# frozen_string_literal: true

require 'spec_helper'

describe Priloo::Preloaders::BmInjectorPreloader do
    let(:post) { Post.create!(user: User.create!) }
    let(:preloader) { described_class.new(Post, :answer_to_life) }

    describe '#dependencies' do
        it { expect(preloader.dependencies).to be_empty }
    end

    describe '#preload' do
        let(:preloaded_list) { preloader.preload([post]) }
        it { expect(preloaded_list).to eq [42] }
    end
end
