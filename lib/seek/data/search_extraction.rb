module Seek
  module Data
    module SearchExtraction
      include SysMODB::SpreadsheetExtractor

      #returns an array of all cell content within the workbook.
      def spreadsheet_contents_for_search obj=self
        if obj.content_blob.is_extractable_spreadsheet?
          content = Rails.cache.fetch("#{obj.content_blob.cache_key}-ss-content-for-search") do
            begin
              xml=obj.spreadsheet_xml
              unless xml.nil?
                content = extract_content(xml)
                content = filter_content(content)
                content = humanize_content(content)
                content
              else
                []
              end
            rescue Exception=>e
              Rails.logger.error("Error processing spreadsheet for content_blob #{obj.content_blob.id} #{e}")
              raise e unless Rails.env.production?
              nil
            end
          end
        else
          Rails.logger.error("Unable to find file contents for #{obj.class.name} #{obj.id}")
        end
        content || []
      end

      private

      #filters out numbers and text declared in a black list
      def filter_content content
        blacklist = ["SEEK ID"] #not yet defined, and should probably be regular expressions
        content = content - blacklist

        #filter out numbers
        content.reject! do |val|
          val.to_s.match(/\A[+-]?\d+?(\.\d+)?\Z/) != nil
        end
        content
      end

      #pulls out all the content from cells into an array
      def extract_content xml

        doc = LibXML::XML::Parser.string(xml).parse
        doc.root.namespaces.default_prefix="ss"

        content = doc.find("//ss:sheet[@hidden='false' and @very_hidden='false']/ss:rows/ss:row/ss:cell").collect do |cell|
          cell.content
        end
        content.reject!{|v| v.blank?}
        content.uniq!
        content
      end

      #does some manipulation of the content, e.g. converting camelcase and converting underscores, whilst preserving the original
      #form
      def humanize_content content
        content.collect do |val|
          [content,val.underscore.humanize.downcase]
        end.flatten.uniq
      end
    end
  end
end