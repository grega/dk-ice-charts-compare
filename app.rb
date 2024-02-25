require 'sinatra'
require 'nokogiri'
require 'open-uri'
require 'cgi'

# Fetch dates and PDF URLs
def fetch_dates_and_urls
  # URL of the webpage to scrape
  url = 'https://ocean.dmi.dk/arctic/icecharts_capefarewell_frame_content.php'

  # Fetch and parse the HTML document
  doc = Nokogiri::HTML(URI.open(url))

  # Initialize arrays to store dates and PDF URLs
  dates = []
  pdf_urls = []

  # Select all td elements
  td_elements = doc.css('td')

  # Iterate through each td element
  td_elements.each do |td|
    # Find the input element within the td
    input_element = td.at_css('input[name="selected_modis_img"]')

    # If input element exists and has a value attribute
    if input_element && input_element['value']
      # Extract the URL from the value attribute
      pdf_url = input_element['value']

      # Extract the date from the PDF filename and convert to human-readable format
      date = pdf_url[/\d{12}/]
      human_readable_date = "#{date[6..7]}-#{date[4..5]}-#{date[0..3]}"

      # Store the date and PDF URL in arrays
      dates << human_readable_date
      pdf_urls << "https://ocean.dmi.dk/arctic/#{pdf_url}.pdf"
    end
  end

  [dates, pdf_urls]
end

# Route to render the index page
get '/' do
  @dates, @pdf_urls = fetch_dates_and_urls
  erb :index, locals: { dates: @dates, pdf_urls: @pdf_urls }
end
