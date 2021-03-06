require 'helper'
require 'pathname'

class TestRtesseract < Test::Unit::TestCase
  context "Path" do
    setup do
      @path = Pathname.new(__FILE__.gsub("test_rtesseract.rb","")).expand_path
      @image_tiff = @path.join("images","test.tif").to_s
    end

    should "be instantiable" do
      assert_equal RTesseract.new.class , RTesseract
      assert_equal RTesseract.new("").class , RTesseract
      assert_equal RTesseract.new(@image_tiff).class , RTesseract
    end

    should "translate image to text" do
      assert_equal RTesseract.new(@image_tiff).to_s_without_spaces , "43ZZ"
      assert_equal RTesseract.new(@path.join("images","test1.tif").to_s).to_s_without_spaces , "V2V4"
      assert_equal RTesseract.new(@path.join("images","test with spaces.tif").to_s).to_s_without_spaces , "V2V4"
    end

    should "translate images .png, .jpg, .bmp" do
      assert_equal RTesseract.new(@path.join("images","test.png").to_s).to_s_without_spaces , "HW9W"
      assert_equal RTesseract.new(@path.join("images","test.jpg").to_s).to_s_without_spaces , "3R8Z"
      assert_equal RTesseract.new(@path.join("images","test.bmp").to_s).to_s_without_spaces , "ZLA6"
    end

    should "change the image" do
      image = RTesseract.new(@image_tiff)
      assert_equal image.to_s_without_spaces,"43ZZ"
      image.source = @path.join("images","test1.tif").to_s
      assert_equal image.to_s_without_spaces,"V2V4"
    end

    should "select the language" do
      #English
      assert_equal RTesseract.new(@image_tiff,{:lang=>"eng"}).lang , " -l eng "
      assert_equal RTesseract.new(@image_tiff,{:lang=>"en"}).lang , " -l eng "
      assert_equal RTesseract.new(@image_tiff,{:lang=>"en-US"}).lang , " -l eng "
      assert_equal RTesseract.new(@image_tiff,{:lang=>"english"}).lang , " -l eng "

      #Portuguese
      assert_equal RTesseract.new(@image_tiff,{:lang=>"por"}).lang , " -l por "
      assert_equal RTesseract.new(@image_tiff,{:lang=>"pt-BR"}).lang , " -l por "
      assert_equal RTesseract.new(@image_tiff,{:lang=>"pt-br"}).lang , " -l por "
      assert_equal RTesseract.new(@image_tiff,{:lang=>"pt"}).lang , " -l por "
      assert_equal RTesseract.new(@image_tiff,{:lang=>"portuguese"}).lang , " -l por "

      assert_equal RTesseract.new(@image_tiff,{:lang=>"eng"}).to_s_without_spaces , "43ZZ"
      assert_equal RTesseract.new(@image_tiff,{:lang=>"por"}).to_s_without_spaces , "43ZZ"

      assert_equal RTesseract.new(@image_tiff,{:lang=>"eng"}).lang , " -l eng "
    end

    should "be configurable" do
      assert_equal RTesseract.new(@image_tiff,{:chop_enable=>0,:enable_assoc=>0,:display_text=>0}).config , "chop_enable 0\nenable_assoc 0\ndisplay_text 0"
      assert_equal RTesseract.new(@image_tiff,{:chop_enable=>0}).config , "chop_enable 0"
      assert_equal RTesseract.new(@image_tiff,{:chop_enable=>0,:enable_assoc=>0}).config , "chop_enable 0\nenable_assoc 0"
      assert_equal RTesseract.new(@image_tiff,{:chop_enable=>0}).to_s_without_spaces , "43ZZ"
    end

    should "crop image" do
      assert_equal RTesseract.new(@image_tiff).crop!(140,10,36,40).to_s_without_spaces, "4"
      assert_equal RTesseract.new(@image_tiff).crop!(180,10,36,40).to_s_without_spaces, "3"
      assert_equal RTesseract.new(@image_tiff).crop!(200,10,36,40).to_s_without_spaces, "Z"
      assert_equal RTesseract.new(@image_tiff).crop!(220,10,30,40).to_s_without_spaces, "Z"
    end

    should "unique uid" do
      assert_not_equal RTesseract.new(@image_tiff).generate_uid , RTesseract.new(@image_tiff).generate_uid
    end

    should "generate a unique id" do
      reg = RTesseract.new(@image_tiff)
      assert_equal reg.generate_uid , reg.generate_uid
      value = reg.generate_uid
      reg.convert
      assert_not_equal value , reg.generate_uid
    end

    should "read image from blob" do
      image = Magick::Image.read(@path.join("images","test.png").to_s).first
      blob = image.white_threshold(245).quantize(256,Magick::GRAYColorspace).to_blob

      test = RTesseract.new
      test.from_blob(blob)
      assert_equal test.to_s_without_spaces , "HW9W"
    end

    should "change image in a block" do
      test = RTesseract.read(@path.join("images","test.png").to_s) do |image|
        image = image.white_threshold(245)
        image = image.quantize(256,Magick::GRAYColorspace)
      end
      assert_equal test.to_s_without_spaces , "HW9W"

      test = RTesseract.read(@path.join("images","test.jpg").to_s,{:lang=>'en'}) do |image|
        image = image.white_threshold(245).quantize(256,Magick::GRAYColorspace)
      end
      assert_equal test.to_s_without_spaces , "3R8Z"
    end
  end
end
