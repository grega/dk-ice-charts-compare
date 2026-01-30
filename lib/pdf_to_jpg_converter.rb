require 'digest'
require 'fileutils'
require 'tempfile'
require 'open-uri'
require 'mini_magick'

class PdfToJpgConverter
  def initialize(output_dir: File.join('tmp', 'images'))
    @output_dir = output_dir
    FileUtils.mkdir_p(@output_dir)
  end

  def convert(pdf_url)
    jpg_path = jpg_path_for(pdf_url)
    return jpg_path if File.exist?(jpg_path)

    Tempfile.create(['icechart', '.pdf']) do |temp_pdf|
      temp_pdf.binmode
      temp_pdf.write(URI.open(pdf_url).read)
      temp_pdf.flush

      MiniMagick::Tool::Convert.new do |convert|
        convert.background 'white'
        convert.alpha 'remove'
        convert.quality '100'
        convert.resize '800x'
        convert << temp_pdf.path
        convert << jpg_path
      end
    end

    jpg_path
  end

  private

  def jpg_path_for(pdf_url)
    filename = "#{Digest::SHA256.hexdigest(pdf_url)}.jpg"
    File.join(@output_dir, filename)
  end
end
