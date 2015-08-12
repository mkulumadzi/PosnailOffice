require_relative '../../spec_helper'

describe Postoffice::FileService do

  describe 'decode a base64 string and return a file' do

    before do
      @string = "This is a string to encode."
      base64_string = Base64.encode64(@string)
      @key = "samplekey"
      @file = File.open(Postoffice::FileService.decode_string_to_file base64_string, @key)
      @file_contents = @file.read
    end

    after do
      @file.close
      File.delete(@file)
    end

    it 'must decode the string and store it in the file' do
      @file_contents.must_equal @string
    end

    it 'must store the key as the name of the file' do
      File.basename(@file).must_equal @key
    end

  end

  describe 'upload file using Dragonfly' do

    before do
      @contents = "I am uploading this file."
      base64_string = Base64.encode64(@contents)
      @filename = "sample.txt"
      data = JSON.parse(('{"file": "'+ base64_string + '", "filename": "' + @filename + '"}').gsub("\n", ""))
      @uid = Postoffice::FileService.upload_file data
    end

    it 'must return a String as the UID' do
      @uid.must_be_instance_of String
    end

    it 'must upload the file to the AWS S3 store' do
      contents = Dragonfly.app.fetch(@uid).data
      contents.must_equal @contents
    end

    it 'must store the filename' do
      Dragonfly.app.fetch(@uid).name.must_equal @filename
    end

    it 'must delete the temporary file' do
      File.exists?('tmp/' + @filename).must_equal false
    end

  end

  describe 'fetch image' do

    before do
      @image = File.open('spec/resources/image2.jpg')
      @uid = Dragonfly.app.store(@image.read, 'name' => 'image2.jpg')
    end

    after do
      @image.close
    end

    describe 'fetch full image' do

      before do
        params = ""
        @image_fetched = Postoffice::FileService.fetch_image @uid, params
      end

      it 'must fetch the image' do
        @image_fetched.name.must_equal 'image2.jpg'
      end

      it 'must fetch the full image' do
        @image_fetched.size.must_equal @image.size
      end

    end

    describe 'fetch image with thumbnail' do

      it 'must resize the image if a thumbnail is given' do
        params = Hash["thumb", "400x"]
        image_fetched = Postoffice::FileService.fetch_image @uid, params
        image_fetched.width.must_equal 400
      end

      it 'must return a Argument Error if the thumbnail parameter is invalid' do
        params = Hash["thumb", "splat"]
        assert_raises ArgumentError do
          image_fetched = Postoffice::FileService.fetch_image @uid, params
          image_fetched.apply
        end
      end

    end

  end

  describe 'get card uids' do

    before do
      @cards = Postoffice::FileService.get_cards
    end

    it 'must return an array' do
      @cards.must_be_instance_of Array
    end

    it 'must contain uids for all of the cards on the s3 bucket at resources/cards, except the root resource' do
      s3 = Aws::S3::Resource.new
      bucket = s3.bucket(ENV['AWS_BUCKET'])
      expected_number = bucket.objects(prefix: 'resources/cards').collect(&:key).count
      @cards.count.must_equal expected_number - 1
    end

    it 'must not contain a reference to the root folder' do
      @cards.index('resources/cards/').must_equal nil
    end

  end

end
