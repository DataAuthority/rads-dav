require 'dav4rack/resource'
require 'erb'
class DavInterceptorController < DAV4Rack::Resource
  attr_accessor :supported_children
  def setup
    @lock_class = nil
    @supported_children = %w{ projects mine }
    @users = {'londo003' => '300odnol'}
  end

  def supports_locking?
    false
  end

  def children
    @supported_children.collect {|c| child("#{c}/") }
  end

  def collection
    true
  end

  def exist?
    true
  end

  def creation_date
    Time.now
  end

  def last_modified
    Time.now
  end

  def last_modified=(time)
    raise Forbidden
  end

  # Return an Etag, an unique hash value for this resource.
  def etag
    sprintf('%x-%x-%x', @path.object_id, 256, Time.now.to_i)
  end

  def resource_type
    :collection
  end

  def content_type
    "text/html"
  end

  def content_length
    256
  end

  def get(request, response)
      template_file = ::File.open(Rails.root.to_s + '/app/views/dav/index.html.erb', 'r')
      erb = ERB.new(template_file.read)
      template_file.close
      response.body = erb.result(binding)
      response['Content-Length'] = response.body.bytesize.to_s
      response['Content-Type'] = 'text/html'
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

  def authenticate(user,pass)
    if @users.has_key?(user) && pass == @users[user]
      @user = RepositoryUser.find_by_netid(user)
      return true
    end
    false
  end

end
