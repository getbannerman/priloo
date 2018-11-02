# frozen_string_literal: true

require 'spec_helper'

describe Priloo::RecursiveInjector do
    describe '#canonicalize' do
        subject { described_class.new.send(:canonicalize, path) }

        context 'basic' do
            let(:path) { :a }
            it { is_expected.to eq(a: {}) }
        end

        context 'empty' do
            let(:path) { [] }
            it { is_expected.to eq({}) }
        end

        context 'strangely formed' do
            let(:path) { [[[[[:nested]]], b: :c], []] }
            it { is_expected.to eq(nested: {}, b: { c: {} }) }
        end

        context 'complex' do
            let(:path) { [:x, :y, v: [:m, a: %i[b c], h: :f]] }
            it { is_expected.to eq(x: {}, y: {}, v: { m: {}, a: { b: {}, c: {} }, h: { f: {} } }) }
        end
    end

    class BaseTestPreloader < Typed::Struct
        attribute :name
        attribute :dependencies, Typed.default([])

        def merge_key
            [name, dependencies]
        end

        def injected?(target)
            target.respond_to?(name)
        end

        def extract(target)
            target.send(name)
        end

        def inject(target, value)
            target.define_singleton_method(name) { value }
            target
        end
    end

    class TestObject < Typed::Struct
        attribute :parent
        attribute :name
        attribute :dependencies, Typed.default([])

        def find_preloader(method)
            method = method.to_s
            return unless method.end_with?('__priloo__')

            property = method.chomp('__priloo__')

            case
            when property.start_with?('many_')
                TestMultiPreloder.new(name: property.to_sym, dependencies: dependencies)
            when property.start_with?('one_')
                TestSinglePreloder.new(name: property.to_sym, dependencies: dependencies)
            end
        end

        def method_missing(method, *)
            find_preloader(method) || super
        end

        def respond_to_missing?(method, _)
            !find_preloader(method).nil? || super
        end
    end

    class TestMultiPreloder < BaseTestPreloader
        def preload(instances)
            instances.map { |inst|
                [
                    TestObject.new(name: "#{name}_1", parent: inst),
                    TestObject.new(name: "#{name}_2", parent: inst),
                    nil
                ]
            }
        end

        def multiplicity
            1
        end
    end

    class TestSinglePreloder < BaseTestPreloader
        def preload(instances)
            instances.map { |inst| TestObject.new(name: name, parent: inst) }
        end

        def multiplicity
            0
        end
    end

    describe '#preload' do
        let(:object) { TestObject.new(name: 'God', parent: nil) }
        subject { [object].priload(path).first }

        context 'complex hierarchy' do
            let(:path) { [:many_cars, many_mice: { many_cars: :one_truth }, one_lol: :many_lol] }

            it {
                is_expected.to have_attributes(
                    name: 'God',
                    one_lol: have_attributes(name: :one_lol),
                    many_cars: [
                        have_attributes(name: 'many_cars_1'),
                        have_attributes(name: 'many_cars_2'),
                        nil
                    ],
                    many_mice: [
                        have_attributes(
                            name: 'many_mice_1',
                            many_cars: [
                                have_attributes(name: 'many_cars_1'),
                                have_attributes(name: 'many_cars_2'),
                                nil
                            ]
                        ),
                        have_attributes(
                            name: 'many_mice_2',
                            many_cars: [
                                have_attributes(name: 'many_cars_1', one_truth: have_attributes(name: :one_truth)),
                                have_attributes(name: 'many_cars_2', one_truth: have_attributes(name: :one_truth)),
                                nil
                            ]
                        ),
                        nil
                    ]
                )
            }
        end

        context 'with already preloaded property' do
            let(:path) { %i[many_cars many_mice one_house] }

            before { object.define_singleton_method(:many_mice) { %i[luke_skywalker claire_pao] } }
            before { object.define_singleton_method(:one_house) { :yeah } }

            it {
                is_expected.to have_attributes(
                    name: 'God',
                    many_cars: [
                        have_attributes(name: 'many_cars_1'),
                        have_attributes(name: 'many_cars_2'),
                        nil
                    ],
                    many_mice: %i[luke_skywalker claire_pao],
                    one_house: :yeah
                )
            }
        end
    end
end
