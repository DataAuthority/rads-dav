require 'dav4rack/resource'
require 'dav4rack/file'
require 'erb'

class DavProjectsController < DAV4Rack::Resource
  attr_accessor :requested_record, :requested_project, :is_collection, :users

  def setup
    @requested_record = @requested_project = @is_collection = nil
    @lock_class = nil
    @users = {'londo003' => '300odnol'}
  end

  def supports_locking?
    false
  end

  # If this is a collection, return the child resources.
  def children
    if exist? && collection?
      if root_path?
        return @user.projects.collect { |up| child("#{ up.name }/") }
      else
        if @requested_record
          return [ child( @requested_record.content_file_name ) ]
        elsif @requested_project
          return @requested_project.project_affiliated_records.collect { |ar| child("#{ ar.record_id }/") }
        end
      end
    end
    []
  end

  # Is this resource a collection?
  def collection?
    return @is_collection
  end

  # Does this resource exist?
  def exist?
    if (@is_collection || @requested_project || @requested_record)
      return true
    else
      if root_path?
        @is_collection = true
        return true
      else
        (slash, pname, rid, rname) = @path.split('/')
        requested_record = nil
        requested_project = @user.projects.find_by(name: pname)
        if requested_project.nil?
          return false
        end

        if rname
          requested_record = requested_project.records.find_by(id: rid, content_file_name: rname)
          return false if requested_record.nil?
        elsif rid
          requested_record = requested_project.records.find_by(id: rid)
          return false if requested_record.nil?
          @is_collection = true
        else
          @is_collection = true
        end
        @requested_project = requested_project
        @requested_record = requested_record
        return true
      end
    end
  end

  # Return the creation time.
  def creation_date
    if exist?
      if @requested_record
        @requested_record.created_at
      elsif @requested_project
        @requested_project.created_at
      else
        Time.now
      end
    end
  end

  # Return the time of last modification.
  def last_modified
    if exist?
      if @requested_record
        @requested_record.created_at
      elsif @requested_project
        @requested_project.updated_at
      else
        Time.now
      end
    end
  end

  def last_modified=(time)
    raise Forbidden
  end

  # Return an Etag, an unique hash value for this resource.
  def etag
    if exist?
      if @requested_record
        requested_record.content_fingerprint
      else
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
    if exist?
      if collection?
        "text/html"
      else
        @requested_record.content_content_type
      end
    end
  end

  # Return the size in bytes for this resource.
  def content_length
    if exist?
      if collection?
        256
      else
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
      template_file = ::File.open(Rails.root.to_s + '/app/views/dav/projectrecords/index.html.erb', 'r')
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
    raise Forbidden
  end
    
  def post(request, response)
    raise Forbidden
  end
    
  def delete
    raise Forbidden
  end

  def copy(dest, overwrite=false)
    raise Forbidden
  end
  
  def move(dest, overwrite=false)
    raise Forbidden
  end

  def name
    ::File.basename(@path)
  end

  private

  def root_path?
    (@path.to_s.empty? || @path.split("/").length == 0)
  end

  def authenticate(user,pass)
    if @users.has_key?(user) && pass == @users[user]
      @user = RepositoryUser.find_by_netid(user)
      true
    else
      false      
    end
  end
end
