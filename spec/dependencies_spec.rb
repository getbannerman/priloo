# frozen_string_literal: true

require 'spec_helper'

describe Priloo::Dependencies do
    subject { described_class.resolve(input) }

    context 'Simple case' do
        let(:input) { { D: [], C: [:D], A: [:B], B: [:C] } }
        it { is_expected.to eq %i[D C B A] }
    end

    context 'Cycle' do
        let(:input) { { A: [:B], B: [:C], C: [:D], D: [:A] } }
        it { is_expected_block.to raise_error TSort::Cyclic }
    end

    context 'Missing dep' do
        let(:input) { { A: [:B], B: %i[C D], D: %i[C B] } }
        it { is_expected_block.to raise_error KeyError }
    end

    context 'Complex case' do
        let(:input) { { A: %i[B E], B: %i[C D], D: [:C], E: [:C], C: [] } }
        it {
            is_expected.to(satisfy { |x|
                [%i[C E D B A], %i[C D E B A], %i[C D B E A]].include?(x)
            })
        }
    end
end
