# frozen_string_literal: true

require 'spec_helper'

describe Priloo::Preloaders::ArAssociationPreloader do
    let(:post) { Post.create!(user: User.create!) }
    let(:preloader) { described_class.new(Post, :user) }

    before { post.send(:clear_association_cache) }

    describe '#dependencies' do
        it { expect(preloader.dependencies).to be_empty }
    end

    describe '#preload' do
        let(:preloaded_user) { preloader.preload([post]).first }
        it { expect(preloader.injected?(post)).to be_falsy }
        it { expect(preloaded_user.posts).to eq [post] }

        class Dpost < SimpleDelegator; end

        context 'when active_record is behind a delegator' do
            let(:delegated_post) { Dpost.new(post) }
            let(:preloaded_user) { preloader.preload([delegated_post]).first }

            it { expect(preloader.injected?(post)).to be_falsy }
            it { expect(preloaded_user.posts).to eq [post] }
        end
    end
end
