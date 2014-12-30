# PDF TEXT EXTRACTION FOR SEARCHING - TESTBED
---
## OVERVIEW
I put this testbed together to be able to test different methods for extracting text from different PDF variants in a controlled environment. Basically, there is a /pdf folder that holds copies of test PDF files with different attributes (different fonts, DPI, encodings, generators, generation methods, etc) that can be fed into my extract_pdf_text() method which attempts to flatten the PDF, then introspect & extract its text. If that fails (generally because it's a scanned PDF), ImageMagick is used to convert each page of the PDF to a massaged, image (JPG) representation of it, then Tesseract OCR is applied to those page images to extract any recognizable text within. Finally, another transformation is applied to the raw text to get a unique collection of words that can be stored and used for efficient doc searching.

## HOW TO USE

0. Assumption: Ruby 2+ installed
1. Clone it
2. $ cd pdf-text-extraction
3. Install dependencies (see below)
4. $ ruby testbed.rb
5. Enter a filename of a test PDF to process
6. Extracted PDF info will be output to console
  * ModDate
  * CreationDate
  * Author
  * Title
  * Creator
  * Producer
  * RawWordLength (of extracted text)
  * RawText (extracted text)
  * TokenLength (of unique word collection)
  * Tokens (unique word collection)

## STATUS

At this point, text extraction success is pretty good. Of course, text-based (non-scanned) documents yield better results. There are potential text parsing problems when PDFs include fonts with "custom" encoding, where text is generally recognized, but can be 'jammed' together (i.e., "codereview" instead of "code review"). 

Of course, documents with security applied (password, certificate, etc) can not be accessed and processed.

Text-based documents are processed pretty efficiently via the pdf-reader gem. Scanned documents are much less efficient, requiring that each page be converted to high-res images, then OCR applied to each page individually. Special consideration should be made on file size when processing such files.

---

## NOTES - CPAYNE, 12/19/2014
### EXTRACTED TEXT FILTERING
* strip extraneous whitespace [done]
* bounce against dictionary and toss anything not found [done]
* discard anything (non-numeric && < 3 chars) (?)
* we don't care about duplicates; discard [done]

### EXTRACTING PDF TEXT
* if not scanned, good to go
* if scanned (image-based), need to 1) convert to image, 2) process/massage image, 3) apply OCR to extract as much text as possible
* will need __async file processing__ (have a PROCESSING flag or something for UI)


## DEPENDENCIES
---

### INSTALL PACKAGES ON SERVER

__INSTALL PDFTK - PURPOSE: INITIAL PDF FLATTENING (FLATTENING ALLOWS FOR EXTRACTING PDF FORM *VALUES*)__

https://www.pdflabs.com/tools/pdftk-server/

__INSTALL IMAGEMAGICK - PURPOSE: PDF-TO-IMAGE CONVERSION AND MANIPULATION FOR OCR PREPARATION__
```
$ brew install ImageMagick
```
__INSTALL LEPTONICA & TESSERACT__
```
$ brew install leptonica
$ brew install tesseract
```
__INSTALL PDF-READER GEM__
```
gem install pdf-reader
```
__INSTALL TESSERACT (OCR ENGINE)__
```
gem install tesseract
```
__INSTALL TESSERACT-OCR GEM (RUBY WRAPPER FOR TESSERACT)__
```
gem install tesseract-ocr
```


## TODO
---

1. SANITIZE(!) extract_to_pdf parameters(!)


