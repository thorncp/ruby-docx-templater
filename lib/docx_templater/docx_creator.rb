module DocxTemplater
  class DocxCreator
    attr_reader :template_path, :template_processor

    def initialize(template_path, data, escape_html=true)
      @template_path = template_path
      @template_processor = TemplateProcessor.new(data, escape_html)
    end

    def generate_docx_file(file_name = "output_#{Time.now.strftime("%Y-%m-%d_%H%M")}.docx", encoding = nil)
      buffer = generate_docx_bytes
      mode = encoding ? "w:#{encoding}" : "w"
      File.open(file_name, mode) { |f| f.write(buffer) }
    end

    def generate_docx_bytes
      buffer = ''
      read_existing_template_docx do |template|
        create_new_zip_in_memory(buffer, template)
      end
      buffer
    end

    private

    def copy_or_template(entry_name, f)
      # Inside the word document archive is one file with contents of the actual document. Modify it.
      return template_processor.render(f.read) if entry_name == 'word/document.xml'
      f.read
    end

    def read_existing_template_docx
      ZipRuby::Archive.open(template_path) do |template|
        yield template
      end
    end

    def create_new_zip_in_memory(buffer, template)
      n_entries = template.num_files
      ZipRuby::Archive.open_buffer(buffer, ZipRuby::CREATE) do |archive|
        n_entries.times do |i|
          entry_name = template.get_name(i)
          template.fopen(entry_name) do |f|
            archive.add_buffer(entry_name, copy_or_template(entry_name, f))
          end
        end
      end
    end
  end
end
