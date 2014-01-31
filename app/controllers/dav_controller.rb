require 'dav4rack/resource'
require 'dav4rack/file'
require 'erb'

class DavController < DAV4Rack::Resource
  attr_accessor :folders, :requested_record, :requested_project, :is_collection, :path_parts, :parent_path, :users

  def setup
    @requested_record = @requested_project = @is_collection = @path_parts = @parent_path = nil
    @lock_class = nil
    @folders = %w{ mine projects }
    @users = {'user' => 'password'}
  end

  def supports_locking?
    # TODO '/upload @path
    false
  end

  def parent
    unless root_path?
      if exist? && collection?
        parent = self.class.new(
                                @parent_path,
                                ::File.split(@path).first,
                                @request,
                                @response,
                                @options.merge(
                                               :user => @user
                                               )
                                )
        parent
      end
    end
  end

  # If this is a collection, return the child resources.
  def children
    # TODO '/upload @path request
    chitlins = []
    if exist? && collection?
      if root_path?
        chitlins = @folders.map do |folder|
          child(folder + '/')
        end
      elsif @path_parts.length == 1
        if @path_parts[0] == 'mine'
          chitlins = @user.records.map do |ur|
            child("#{ ur.id }/")
          end
        elsif @path_parts[0] = 'projects'
          chitlins = @user.projects.map do |up|
            child("#{ up.name }/")
          end
        end
      else
        if @requested_record
          chitlins = [ child( @requested_record.content_file_name ) ]
        elsif @requested_project
          chitlins = @requested_project.affiliated_records.map do |ar|
            child("#{ ar.record_id }/")
          end
        end
      end
    end
    chitlins
  end

  # Is this resource a collection?
  def collection?
    return @is_collection
  end

  # Does this resource exist?
  def exist?
    resource_exists = false
    if @parent_path
      resource_exists = (@is_collection || @requested_project || @requested_record)
    else
      if root_path?
        resource_exists = true
        @is_collection = true
      else
        @path_parts = @path.split('/')
        @path_parts.shift
        if @folders.include? @path_parts[0]
          if @path_parts.length == 1
            resource_exists = true
            @is_collection = true
          else
            case @path_parts[0]
            when 'mine'
              if @path_parts.length >= 2
                # /mine/record_id
                # /mine/record_id/record_name
                if (@path_parts.length == 2)
                  @is_collection = true
                  @requested_record = @user.records.find_by(id: @path_parts[1])
                else
                  @requested_record = @user.records.find_by(id: @path_parts[1], content_file_name: @path_parts[2])
                end
                resource_exists = !(@requested_record.nil?)
              end
            when 'projects'
              @requested_project = @user.projects.find_by(name: @path_parts[1])
              if @requested_project.nil?
                resource_exists = false
              else
                if @path_parts.length == 2
                  # /projects/project_id
                  @is_collection = true
                  resource_exists = true
                elsif @path_parts.length >= 3
                  # /projects/project_id/record_id
                  # /projects/project_id/record_id/record_name
                  if (@path_parts.length == 3)
                    @is_collection = true
                    @requested_record = @requested_project.records.find_by(id: @path_parts[2])
                  else
                    @requested_record = @requested_project.records.find_by(id: @path_parts[2], content_file_name: @path_parts[3])
                  end
                  resource_exists = !(@requested_record.nil?)
                end
              end
            end
          end
        end
      end
    end
    return resource_exists
  end

  # Return the creation time.
  def creation_date
    if exist?
      if collection?
        if @requested_project
          @requested_project.created_at
        elsif @requested_record
          @requested_record.created_at
        else
          Time.now
        end
      else
        @requested_record.created_at
      end
    end
  end

  # Return the time of last modification.
  def last_modified
    if exist?
      if collection?
        if @requested_project
          @requested_project.updated_at
        elsif @requested_record
          @requested_record.created_at
        else
          Time.now
        end
      else
        @requested_record.created_at
      end
    end
  end

  def last_modified=(time)
    raise Forbidden
  end

  # Return an Etag, an unique hash value for this resource.
  def etag
    # TODO '/upload @path request
    if exist?
      if @requested_record
        requested_record.content_fingerprint
      else
        # @path == '/' ? @path.object_id, 256, Time.now.to_i : @stored_query.id, 256, Time.now.to_i
        sprintf('%x-%x-%x', @path.object_id, 256, Time.now.to_i)
      end
    end
  end

  # Return the resource type. Generally only used to specify
  # resource is a collection.
  def resource_type
    if exist?
      :collection if collection?
    end
  end

  # Return the mime type of this resource.
  def content_type
    # TODO '/upload @path request
    if exist?
      if collection?
        "text/html"
      else
        # @stored_query_file.content_type
        @requested_record.content_content_type
      end
    end
  end

  # Return the size in bytes for this resource.
  def content_length
    # TODO '/upload @path request
    if exist?
      if collection?
        256
      else
        # @stored_query_file.size
        @requested_record.content_file_size
      end
    end
  end

  # HTTP GET request.
  #
  # Write the content of the resource to the response.body.
  def get(request, response)
    raise NotFound unless exist?
    if collection?
      template_file = ::File.open(Rails.root.to_s + '/app/views/dav/index.html.erb', 'r')
      erb = ERB.new(template_file.read)
      template_file.close
      response.body = erb.result(binding)
      response['Content-Length'] = response.body.bytesize.to_s
      response['Content-Type'] = 'text/html'
    else
      file = DAV4Rack::File.new(@requested_record.content.path)
      response.body =file
    end
  end

  def put(request, response)
    # TODO '/upload @path request
    raise Forbidden
  end
    
  def post(request, response)
    # TODO '/upload @path requets
    raise Forbidden
  end
    
  def delete
    # TODO '/upload @path request
    raise Forbidden
  end

  def copy(dest, overwrite=false)
    # TODO '/upload @path request where dest within /upload
    raise Forbidden
  end
  
  def move(dest, overwrite=false)
    # TODO '/upload @path request where dest within /upload
    raise Forbidden
  end

  def name
    ::File.basename(@path)
  end

  def allows_redirect?
    user_agent = request.respond_to?(:user_agent) ? request.user_agent.to_s.downcase : request.env['HTTP_USER_AGENT'].to_s.downcase
    Rails.logger.error("Checking #{ user_agent } for allow_redirect")
    %w(cyberduck konqueror mozilla safari chrome).any?{|x| (user_agent) =~ /#{Regexp.escape(x)}/}
  end

  private

  def root_path?
    (@path.to_s.empty? || @path.split("/").length == 0)
  end

  def authenticate(user,pass)
    # TODO '/upload @path request
    # use @user and @abililty on @stored_query and @stored_query_file
    if @users.has_key?(user) && pass == @users[user]
      @user = RepositoryUser.find_by_netid('londo003')
      true
    else
      false      
    end
  end
end
