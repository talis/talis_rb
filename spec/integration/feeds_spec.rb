require_relative '../spec_helper'

describe Talis::Feed do
  describe 'POST /annotations' do
    context 'with a valid annotation' do
      before do
        @single_annotation = Talis::Feed::Annotation.create
      end

      it 'should create an annotation' do
      end

      # rubocop:disable Metrics/LineLength
      context 'with a further set of valid annotations with the same target URI' do
        before do
          @annotations = []
          2.times { @annotations << Talis::Feed::Annotation.create }
        end

        it 'should create a feed with two annotations' do
          @feed = Talis::Feed.get
          # this wont work - we want to compare the content
          @feed.annotations.sort.should == @annotations.sort
        end
      end
    end
  end
end
