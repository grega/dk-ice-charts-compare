require 'nokogiri'
require 'open-uri'

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
    human_readable_date = "#{date[6..7]}-#{date[4..5]}-#{date[0..3]} #{date[8..9]}:#{date[10..11]}"
    
    # Store the date and PDF URL in arrays
    dates << human_readable_date
    pdf_urls << "https://ocean.dmi.dk/arctic/#{pdf_url.sub('.ISKO', '.pdf')}"
  end
end

# HTML template for the webpage
html_template = <<~HTML
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Embedded PDF Viewer</title>
</head>
<body>
  <div style="display: flex; justify-content: space-around;">
    <form action="/view-pdf" method="post">
      <select name="pdf_url">
        <% dates.each_with_index do |date, index| %>
          <option value="<%= pdf_urls[index] %>"><%= date %></option>
        <% end %>
      </select>
      <button type="submit">View PDF</button>
    </form>
    <form action="/view-pdf" method="post">
      <select name="pdf_url">
        <% dates.each_with_index do |date, index| %>
          <option value="<%= pdf_urls[index] %>"><%= date %></option>
        <% end %>
      </select>
      <button type="submit">View PDF</button>
    </form>
  </div>
</body>
</html>
HTML

# Save HTML template to a file
File.write('index.html', html_template)
