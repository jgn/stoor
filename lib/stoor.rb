require 'stoor/logger'
require 'stoor/github_auth'
require 'stoor/git_config'
require 'stoor/decorate'
require 'stoor/add_after'
require 'stoor/views/layout'
require 'stoor/views/logout'

# In at least gollum 2.4.13 and later:
#   https://github.com/gollum/gollum/blob/master/lib/gollum/uri_encode_component.rb#L36
# seems to get scoped funny, and I see this:
#   NoMethodError - undefined method `URIEncodeComponent' for #<URI::Parser:0x007f91db50bd78>:
# This fixes it.
if RUBY_VERSION == '1.9.2'
  def encodeURIComponent(componentString)
    ::URI::URIEncodeComponent(componentString)
  end
end
