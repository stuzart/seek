class SampleControlledVocab < ActiveRecord::Base
  attr_accessible :title, :description, :sample_controlled_vocab_terms_attributes

  has_many :sample_controlled_vocab_terms, inverse_of: :sample_controlled_vocab

  validates :title, presence: true, uniqueness: true

  accepts_nested_attributes_for :sample_controlled_vocab_terms, allow_destroy: true

  def labels
    sample_controlled_vocab_terms.collect(&:label)
  end

  def includes_term?(value)
    labels.include?(value)
  end
end
