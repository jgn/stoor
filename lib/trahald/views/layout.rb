class Trahald::Auth
  module Views
    class Layout < Precious::Views::Layout
      def self.template_file
        # Steal Gollum's layout so we get the CSS, JavaScript, etc.
        @template_file ||= File.join(File.dirname(Precious::App.new!.method(:wiki_page).source_location[0]), 'templates', 'layout.mustache')
      end
    end
  end
end
