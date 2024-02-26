require 'sinatra'
require 'nokogiri'
require 'open-uri'
require 'cgi'
require 'mini_magick'

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

# Route to convert PDF to JPG
# Route to convert PDF to JPG
get '/pdf_to_jpg' do
  pdf_url = params[:pdf_url]

  # Generate a unique filename based on the PDF URL
  jpg_filename = "#{CGI.escape(pdf_url)}.jpg"
  jpg_path = File.join('tmp', 'images', jpg_filename)

  # Check if the JPG already exists
  unless File.exist?(jpg_path)
    # Download PDF file
    pdf_data = URI.open(pdf_url).read
    pdf_path = "tmp/temp.pdf"
    File.write(pdf_path, pdf_data)

    # Convert PDF to JPG using mini_magick
    MiniMagick::Tool::Convert.new do |convert|
      convert.background 'white'
      convert.alpha 'remove'
      convert.quality '100'
      convert.resize '800x'
      convert << pdf_path
      convert << jpg_path
    end
  end

  # Serve the pre-generated JPG file
  send_file jpg_path, type: 'image/jpeg', disposition: 'inline'
end

# Route to handle form submission and display images
get '/previous' do
  selected_date = params[:selected_date]
  dates, pdf_urls = fetch_dates_and_urls
  selected_index = dates.index(selected_date)

  # If selected date exists
  if selected_index
    @selected_date = selected_date
    @selected_image_url = pdf_urls[selected_index]

    # Fetch images for previous dates (1 to 90 days before selected date)
    @prev_images_urls = {}
    (1..60).each do |days_before|
      prev_date = (Date.parse(selected_date) - days_before).strftime("%d-%m-%Y")
      prev_index = dates.index(prev_date)
      if prev_index
        @prev_images_urls[prev_date] = pdf_urls[prev_index]
      end
    end
  end

  erb :previous, locals: { dates: dates, pdf_urls: pdf_urls }
end
