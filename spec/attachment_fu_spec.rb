require File.dirname(__FILE__) + '/spec_helper'

module AttachmentFu
  class BasicAsset < ActiveRecord::Base
    extend FauxAsset
    is_attachment
  end

  describe "AttachmentFu" do
    describe "pending creation" do
      before do
        @asset = BasicAsset.new(:content_type => 'application/x-ruby', :temp_path => __FILE__)
      end

      it "has nil #full_filename" do
        @asset.full_filename.should be_nil
      end
      
      it "has nil #partitioned_path" do
        @asset.partitioned_path.should == nil
      end
    end
    
    describe "being created" do
      before :all do
        @file = File.join(File.dirname(__FILE__), 'guinea_pig.rb')
        FileUtils.cp __FILE__, @file
  
        @asset = BasicAsset.create!(:content_type => 'application/x-ruby', :temp_path => @file)
      end
      
      after :all do
        @asset.destroy
      end
      
      it "stores asset in AttachmentFu root_path" do
        @asset.full_filename.should == File.join(AttachmentFu.root_path, "public/afu_spec_assets/#{@asset.partitioned_path * '/'}/guinea_pig.rb")
      end
      
      it "creates partitioned path from the record id" do
        @asset.partitioned_path.each { |piece| piece.should match(/^\d{4}$/) }
        @asset.partitioned_path.join.to_i.should == @asset.id
      end
      
      it "moves temp_path to new location" do
        File.exist?(@asset.full_filename).should == true
      end
      
      it "removes old temp_path location" do
        File.exist?(@file).should == false
      end
      
      it "clears #temp_path" do
        @asset.temp_path.should be_nil
      end
    end
    
    describe "being deleted" do
      before :all do
        @file = File.join(File.dirname(__FILE__), 'guinea_pig.rb')
        FileUtils.cp __FILE__, @file

        @asset  = BasicAsset.create!(:content_type => 'application/x-ruby', :temp_path => @file)
        @asset.destroy
      end
      
      it "removes the file" do
        File.exist?(@asset.full_filename).should == false
      end
    end

    describe "setting temp_path" do
      describe "with a String" do
        before { @asset = BasicAsset.new(:temp_path => __FILE__) }
        it "guesses filename" do
          @asset.filename.should == File.basename(__FILE__)
        end
        
        it "sets #size" do
          @asset.size.should == File.size(__FILE__)
        end
      end

      describe "with a Pathname" do
        before { @asset = BasicAsset.new(:temp_path => Pathname.new(__FILE__)) }
        it "guesses filename" do
          @asset.filename.should == File.basename(__FILE__)
        end
        
        it "sets #size" do
          @asset.size.should == File.size(__FILE__)
        end
      end
      
      describe "with a Tempfile" do
        before do
          @tmp = Tempfile.new File.basename(__FILE__)
          @tmp.write IO.read(__FILE__)
          @asset = BasicAsset.new(:temp_path => @tmp)
        end

        it "guesses filename" do
          name, ext = File.basename(__FILE__).split(".")
          @asset.filename.should include(name) # tempfile adds extra characters to the end
          @asset.filename.should match(/\.rb$/)
        end
        
        it "sets #size" do
          @asset.size.should == File.size(__FILE__)
        end
      end
    end

    before :all do
      BasicAsset.setup_spec_env
    end
    
    after :all do
      BasicAsset.drop_spec_env
      FileUtils.rm_rf AttachmentFu.root_path
    end
  end
end