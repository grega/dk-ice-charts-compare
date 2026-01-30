require 'nokogiri'
require 'open-uri'

class IceChartFetcher
  INDEX_URL = 'https://ocean.dmi.dk/arctic/icecharts_capefarewell_frame_content.php'
  PDF_BASE_URL = 'https://ocean.dmi.dk/arctic'

  def fetch_index
    doc = Nokogiri::HTML(URI.open(INDEX_URL))
    dates = []
    pdf_urls = []

    doc.css('td').each do |td|
      input_element = td.at_css('input[name="selected_modis_img"]')
      next unless input_element && input_element['value']

      pdf_slug = input_element['value']
      date = pdf_slug[/\d{12}/]
      next unless date

      human_readable_date = "#{date[6..7]}-#{date[4..5]}-#{date[0..3]}"

      dates << human_readable_date
      pdf_urls << "#{PDF_BASE_URL}/#{pdf_slug}.pdf"
    end

    [dates, pdf_urls]
  end
end
