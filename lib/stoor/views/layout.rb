if RUBY_VERSION == '1.8.7'
  require 'ruby18_source_location'
end

class Stoor::GithubAuth
  module Views
    class Layout < Precious::Views::Layout
      def self.template_file
        # Steal Gollum's layout so we get the CSS, JavaScript, etc.
        @template_file ||= File.join(File.dirname(Precious::App.new!.method(:wiki_page).source_location[0]), 'templates', 'layout.mustache')
      end
    end
  end
end
