class Oink
  include Redis::Objects

  list :all, :global => true

  hash_key :content, :global => true
  hash_key :created_at, :global => true
  hash_key :handle, :global => true

  attr_accessor :id

  def avatar_url
    "//robohash.org/#{self.handle}.png?size=48x48&amp;bgset=bg2"
  end

  def destroy
    Oink.content.delete(@id)
    Oink.created_at.delete(@id)
    Oink.handle.delete(@id)
    Oink.all.delete(@id)
  end

  def content
    Oink.content[@id]
  end

  def content=(content)
    Oink.content[@id] = content
  end

  def created_at
    Oink.created_at[@id]
  end

  def created_at=(created_at)
    Oink.created_at[@id] = created_at
  end

  def handle
    Oink.handle[@id]
  end

  def handle=(handle)
    Oink.handle[@id] = handle
  end

  def self.create(params)
    c = Oink.new
    c.id = SecureRandom.urlsafe_base64
    c.content = params[:content]
    c.created_at = DateTime.now.utc.iso8601
    c.handle = params[:handle]
    Oink.all.unshift(c.id)
    c
  end

  def self.find(id)
    c = Oink.new
    c.id = id
    c
  end
end
