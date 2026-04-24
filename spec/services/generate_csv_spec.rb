# frozen_string_literal: true

# Copyright (c) Steven Hoffman
# All rights reserved.

require 'spec_helper'

::RSpec.describe ::UnaryPlus::Services::GenerateCsv do
  subject(:service) { described_class.new }

  describe '#call' do
    context 'with an array of hashes' do
      it 'generates a header row from the hash keys' do
        data = [{ name: 'Alice', age: 30 }, { name: 'Bob', age: 25 }]

        rows = ::CSV.parse(service.call(data))

        expect(rows[0]).to eq %w[name age]
      end

      it 'generates data rows from the hash values' do
        data = [{ name: 'Alice', age: 30 }, { name: 'Bob', age: 25 }]

        rows = ::CSV.parse(service.call(data))

        expect(rows[1]).to eq %w[Alice 30]
        expect(rows[2]).to eq %w[Bob 25]
      end

      it 'converts newlines in values to vertical tabs' do
        data = [{ name: "Hello\nWorld", note: 'ok' }]

        rows = ::CSV.parse(service.call(data))

        expect(rows[1][0]).to eq "Hello\vWorld"
      end

      it 'handles nil values without raising' do
        data = [{ name: nil, age: 30 }]

        rows = ::CSV.parse(service.call(data))

        expect(rows[1][0]).to be_nil
      end
    end

    context 'with an array of arrays' do
      it 'generates rows from the nested arrays' do
        data = [%w[name age], %w[Alice 30], %w[Bob 25]]

        rows = ::CSV.parse(service.call(data))

        expect(rows[0]).to eq %w[name age]
        expect(rows[1]).to eq %w[Alice 30]
        expect(rows[2]).to eq %w[Bob 25]
      end

      it 'converts newlines in values to vertical tabs' do
        data = [["Hello\nWorld", 'ok']]

        rows = ::CSV.parse(service.call(data))

        expect(rows[0][0]).to eq "Hello\vWorld"
      end

      it 'wraps non-array rows in an array' do
        data = ['just a string']

        rows = ::CSV.parse(service.call(data))

        expect(rows[0]).to eq ['just a string']
      end
    end

    it 'returns an empty CSV string for empty data' do
      expect(service.call([])).to eq ''
    end
  end
end
