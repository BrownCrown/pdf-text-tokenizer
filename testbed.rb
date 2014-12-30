# CPAYNE, 12/18/2014
# TESTBED FOR PDF TEXT EXTRACTION
# 
# ================================================
# 
# INSTALL PDFTK - INITIAL PDF FLATTENING (FLATTENING ALLOWS FOR EXTRACTING PDF FORM *VALUES*)
# SYNTAX: $ pdftk form_open.pdf output form_open_flat.pdf flatten
# https://www.pdflabs.com/tools/pdftk-server/
#  
# INSTALL IMAGEMAGICK
# brew install ImageMagick
#
# INSTALL LEPTONICA & TESSERACT
# brew install leptonica 
# brew install tesseract
#
# INSTALL PDF-READER GEM
# gem install pdf-reader
#
# INSTALL TESSERACT (OCR ENGINE)
# gem install tesseract
# 
# INSTALL TESSERACT-OCR GEM (RUBY WRAPPER FOR TESSERACT)
# gem install tesseract-ocr

def time(label)

  start = Time.now
  yield
  processing_time = (Time.now - start).to_s
  puts label + ' - Processing Time: ' + processing_time

end

def tokenize_text(raw_text)

  require 'set'

  # In practice, dictionary would be defined globally
  dictionary = File.readlines("dictionary/word").map { |line| line.strip }.to_set # 291k+ Words

  text = raw_text.gsub(/[^0-9a-z]/i,' ').strip.split(' ').each { |word| word.downcase! if dictionary.include?(word.downcase) }.to_set
  text.delete_if { |word| 
    (word.length < 3) ||                                          # less than 3 chars/digits
    (
      word[0, 1] == word[0, 1].downcase &&                        # lowercase word
      word.to_i == 0 &&                                           # alpha
      !dictionary.include?(word) &&                               # not in dictionary
      (
        word[-1, 1] != 's' ||                                     # ends in an 's'
        !dictionary.include?(word[0, word.length - 1])            # stub not in dictionary
      )
    ) 
  }

  return text.to_a.join(" ")

end

def extract_pdf_text(pdf_file, pdf_path = 'pdf') 

  require 'pdf-reader'
  require 'tesseract'

  pdf_file            = pdf_path + '/' + pdf_file 
  pdf_file_flat       = pdf_file + '.flat.pdf'
  unique_image_ref    = Random.new_seed
  image_filename      = unique_image_ref.to_s + '.jpg'
  text                = ''

  if !File.exists?(pdf_file)
    return { :Error => '(extract_pdf_text) Target PDF could not be found' } 
  end

  # FLATTEN
  cmd = 'pdftk ' + pdf_file + ' output ' + pdf_file_flat + ' flatten'
  system( cmd )

  # READ IN PDF
  begin
    reader = PDF::Reader.new(pdf_file_flat)
  rescue
    return { :Error => '(extract_pdf_text) Can not access PDF; this is typically due to Password or Certificate Security being applied to the document' } 
  end

  # ATTEMPT EXTRACTION FROM EACH PAGE
  reader.pages.each do |page| 
    text += page.text
  end

  # IF NO LUCK (IE, SCANNED PDF), CONVERT PAGE(S) TO IMAGE(S) AND OCR
  if text.length < 1

    ocr = Tesseract::Engine.new { |e|
      e.language  = :eng
      e.blacklist = '|'
    }

    # PAGE IMAGE(S)
    cmd = 'convert -trim -density 600 ' + pdf_file_flat + ' -quality 50 -alpha off -blur 1x65000 -threshold 50% -monochrome ' + image_filename
    system( cmd )

    # OCR (IF EXPECTED IMAGE FILE DOESN'T EXIST, IT'S A MULTI-PAGE PDF)
    if File.exists?(image_filename)
      text = ocr.text_for(image_filename).strip 
      File.delete(image_filename)
    else
      page = 0
      page_image_filename = unique_image_ref.to_s + '-' + page.to_s + '.jpg'

      while File.exists?(page_image_filename) do
        text += ocr.text_for(page_image_filename).strip 
        File.delete(page_image_filename)

        page += 1
        page_image_filename = unique_image_ref.to_s + '-' + page.to_s + '.jpg'
      end
    end

  end

  # GATHER AND RETURN EXTRACTED DOC INFO
  doc_info = Hash.new 
  reader.info.each_pair do |sym,val| 
    doc_info[sym] = val
  end

  # STRIP EXTRANEOUS SPACES, LINE BREAKS, AND UNDERSCORES
  doc_info[:RawText], doc_info[:RawWordLength] = text.gsub(/(\n)/,' ').gsub('_',' ').squeeze(' '), text.split(' ').length

  return doc_info

end

# PLAY WITH TEST PDFs

require 'yaml'

pdf_path = 'pdf'

puts "\n\nTEST PDF FILES\n=============="
system ("find #{pdf_path} -maxdepth 1 -type f -name '*.pdf' -not -name '*.flat.pdf'")
puts "==============\n\nProcess which PDF? "

target_file = gets

time('Text Extraction') do
  @doc_info = extract_pdf_text(target_file.chomp, pdf_path)
end

if @doc_info[:RawText].nil?
  puts @doc_info.to_yaml
else
  time('Text Tokenizing') do
    @doc_info[:Tokens] = tokenize_text( @doc_info[:RawText] )
    @doc_info[:TokenLength] = @doc_info[:Tokens].split(' ').length
  end

  # Wrapping in handler
  # Rarely, getting 'invalid byte sequence in UTF-8 (ArgumentError)' when trying to dump via YAML
  begin
    puts @doc_info.to_yaml

    rescue
      puts @doc_info.inspect
  end
end
