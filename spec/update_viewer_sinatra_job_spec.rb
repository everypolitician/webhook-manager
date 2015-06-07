require 'spec_helper'

describe UpdateViewerSinatraJob do
  subject { UpdateViewerSinatraJob.new }

  describe 'push_ref_is_master?' do
    it 'is true when ref is master' do
      subject.push = { 'ref' => 'refs/heads/master' }
      assert subject.push_ref_is_master?
    end

    it 'is false when ref is not master' do
      subject.push = { 'ref' => 'refs/heads/develop' }
      refute subject.push_ref_is_master?
    end
  end

  describe 'countries_json_pushed?' do
    it 'is true when countries.json is added or modified' do
      subject.push = {
        'commits' => [
          { 'added' => ['countries.json'], 'modified' => [] }
        ]
      }
      assert subject.countries_json_pushed?
    end

    it 'is false when countries.json is not changed or modified' do
      subject.push = {
        'commits' => [
          { 'added' => ['README'], 'modified' => [] }
        ]
      }
      refute subject.countries_json_pushed?
    end
  end

  describe 'push_valid?' do
    it 'is true for countries.json pushed to master' do
      subject.push = {
        'ref' => 'refs/heads/master',
        'commits' => [
          { 'added' => ['countries.json'], 'modified' => [] }
        ]
      }
      assert subject.push_valid?
    end
  end
end
