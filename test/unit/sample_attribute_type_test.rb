require 'test_helper'

class SampleAttributeTypeTest < ActiveSupport::TestCase
  test 'valid?' do
    type = SampleAttributeType.new(title: 'x-type', base_type: Seek::Samples::BaseType::INTEGER)
    assert type.valid?
    assert_equal '.*', type.regexp

    type = SampleAttributeType.new(base_type: Seek::Samples::BaseType::INTEGER)
    refute type.valid?

    type = SampleAttributeType.new(title: 'x-type', base_type: 'ActionPack')
    refute type.valid?

    type = SampleAttributeType.new(title: 'x-type', base_type: 'Fish')
    refute type.valid?

    type = SampleAttributeType.new(title: 'x-type', base_type: Seek::Samples::BaseType::INTEGER, regexp: '[')
    refute type.valid?

    type = SampleAttributeType.new(title: 'x-type', base_type: Seek::Samples::BaseType::STRING, regexp: 'xxx')
    assert type.valid?

    type = SampleAttributeType.new(title: 'x-type', base_type: Seek::Samples::BaseType::CV)
    assert type.valid?
  end

  test 'default regexp' do
    type = SampleAttributeType.new(title: 'x-type', base_type: Seek::Samples::BaseType::INTEGER)
    type.save!
    type = SampleAttributeType.find(type.id)
    assert_equal '.*', type[:regexp]
  end

  test 'validate_value' do
    type = SampleAttributeType.new(title: 'x-type', base_type: Seek::Samples::BaseType::STRING, regexp: 'xxx')
    assert type.validate_value?('xxx')
    refute type.validate_value?('fish')
    refute type.validate_value?(nil)

    attribute = SampleAttributeType.new(title: 'fish', base_type: Seek::Samples::BaseType::INTEGER)
    assert attribute.validate_value?(1)
    assert attribute.validate_value?('1')
    assert attribute.validate_value?('01')
    refute attribute.validate_value?('frog')
    refute attribute.validate_value?('1.1')
    refute attribute.validate_value?(1.1)
    refute attribute.validate_value?(nil)
    refute attribute.validate_value?('')

    # refute attribute.validate_value?(1.0)
    #  refute attribute.validate_value?('1.0')

    attribute = SampleAttributeType.new(title: 'fish', base_type: Seek::Samples::BaseType::STRING, regexp: '.*yyy')
    assert attribute.validate_value?('yyy')
    assert attribute.validate_value?('happpp - yyy')
    refute attribute.validate_value?('')
    refute attribute.validate_value?(nil)
    refute attribute.validate_value?(1)
    refute attribute.validate_value?('xxx')

    attribute = SampleAttributeType.new(title: 'fish', base_type: Seek::Samples::BaseType::TEXT, regexp: '.*yyy')
    assert attribute.validate_value?('yyy')
    assert attribute.validate_value?('happpp - yyy')
    refute attribute.validate_value?('')
    refute attribute.validate_value?(nil)
    refute attribute.validate_value?(1)
    refute attribute.validate_value?('xxx')

    attribute = SampleAttributeType.new(title: 'fish', base_type: Seek::Samples::BaseType::FLOAT)
    assert attribute.validate_value?(1.0)
    assert attribute.validate_value?(1.2)
    assert attribute.validate_value?(0.78)
    assert attribute.validate_value?('0.78')
    refute attribute.validate_value?('fish')
    refute attribute.validate_value?('2 Feb 2015')
    refute attribute.validate_value?(nil)

    assert attribute.validate_value?(1.0)
    assert attribute.validate_value?(1)
    assert attribute.validate_value?('1.0')
    assert attribute.validate_value?('012')
    assert attribute.validate_value?('012.3')
    assert attribute.validate_value?('12.30')
    assert attribute.validate_value?('1')

    attribute = SampleAttributeType.new(title: 'fish', base_type: Seek::Samples::BaseType::DATE_TIME)
    assert attribute.validate_value?('2 Feb 2015')
    assert attribute.validate_value?('Thu, 11 Feb 2016 15:39:55 +0000')
    assert attribute.validate_value?('2016-02-11T15:40:14+00:00')
    assert attribute.validate_value?(DateTime.parse('2 Feb 2015'))
    assert attribute.validate_value?(DateTime.now)
    refute attribute.validate_value?(1)
    refute attribute.validate_value?(1.2)
    refute attribute.validate_value?(nil)
    refute attribute.validate_value?('30 Feb 2015')

    attribute = SampleAttributeType.new(title: 'fish', base_type: Seek::Samples::BaseType::DATE)
    assert attribute.validate_value?('2 Feb 2015')
    assert attribute.validate_value?('Thu, 11 Feb 2016 15:39:55 +0000')
    assert attribute.validate_value?('2016-02-11T15:40:14+00:00')
    assert attribute.validate_value?(Date.parse('2 Feb 2015'))
    assert attribute.validate_value?(Date.today)
    refute attribute.validate_value?(1)
    refute attribute.validate_value?(1.2)
    refute attribute.validate_value?(nil)
    refute attribute.validate_value?('30 Feb 2015')
  end

  test 'regular expression match' do
    # whole string must match
    attribute = SampleAttributeType.new(title: 'first name', base_type: Seek::Samples::BaseType::STRING, regexp: '[A-Z][a-z]+')
    assert attribute.validate_value?('Fred')
    refute attribute.validate_value?(' Fred')
    refute attribute.validate_value?('FRed')
    refute attribute.validate_value?('Fred2')
    refute attribute.validate_value?('Fred ')
  end

  test 'web and email regexp' do
    email_type = SampleAttributeType.new title: 'Email address', base_type: Seek::Samples::BaseType::STRING, regexp: RFC822::EMAIL.to_s
    email_type.save!
    email_type.reload
    assert_equal RFC822::EMAIL.to_s, email_type.regexp

    assert email_type.validate_value?('fred@email.com')
    refute email_type.validate_value?('moonbeam')

    web_type = SampleAttributeType.new title: 'Web link', base_type: Seek::Samples::BaseType::STRING, regexp: URI.regexp(%w(http https)).to_s
    web_type.save!
    web_type.reload
    assert web_type.validate_value?('http://google.com')
    assert web_type.validate_value?('https://google.com')
    refute web_type.validate_value?('moonbeam')
  end

  test 'boolean' do
    bool_type = SampleAttributeType.new title: 'bool', base_type: Seek::Samples::BaseType::BOOLEAN
    assert bool_type.valid?
    assert bool_type.validate_value?(true)
    assert bool_type.validate_value?(false)
    refute bool_type.validate_value?('fish')
  end

  test 'to json' do
    type = SampleAttributeType.new(title: 'x-type', base_type: Seek::Samples::BaseType::STRING, regexp: 'xxx')
    assert_equal %({"title":"x-type","base_type":"String","regexp":"xxx"}), type.to_json
  end

  test 'chebi atribute' do
    type = SampleAttributeType.new title: 'CHEBI ID', regexp: 'CHEBI:[0-9]+', base_type: Seek::Samples::BaseType::STRING
    assert type.validate_value?('CHEBI:1111')
    assert type.validate_value?('CHEBI:1121')
    refute type.validate_value?('fish')
    refute type.validate_value?('fish:22')
    refute type.validate_value?('CHEBI:1121a')
    refute type.validate_value?('chebi:222')
  end

  test 'is_controlled_vocab?' do
    type = Factory(:controlled_vocab_attribute_type)
    assert type.controlled_vocab?
    type = Factory(:text_sample_attribute_type)
    refute type.controlled_vocab?
    type = Factory(:boolean_sample_attribute_type)
    refute type.controlled_vocab?
    type = Factory(:sample_sample_attribute_type)
    refute type.controlled_vocab?
  end

  test 'is_seek_sample?' do
    type = Factory(:sample_sample_attribute_type)
    assert type.seek_sample?
    type = Factory(:text_sample_attribute_type)
    refute type.seek_sample?
    type = Factory(:boolean_sample_attribute_type)
    refute type.seek_sample?
    type = Factory(:controlled_vocab_attribute_type)
    refute type.seek_sample?
  end
end
