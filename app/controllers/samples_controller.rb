class SamplesController < ApplicationController
  respond_to :html
  include Seek::PreviewHandling
  include Seek::AssetsCommon
  include Seek::IndexPager

  before_filter :samples_enabled?
  before_filter :find_index_assets, only: :index
  before_filter :find_and_authorize_requested_item, except: [:index, :new, :create, :preview]

  before_filter :auth_to_create, only: [:new, :create]

  include Seek::IsaGraphExtensions

  def index
    if @data_file || @sample_type
      respond_with(@samples)
    else
      super
    end
  end

  def new
    @sample = Sample.new(sample_type_id: params[:sample_type_id])
    respond_with(@sample)
  end

  def create
    @sample = Sample.new(sample_type_id: params[:sample][:sample_type_id], title: params[:sample][:title])
    update_sample_with_params
    flash[:notice] = 'The sample was successfully created.' if @sample.save
    respond_with(@sample)
  end

  def show
    @sample = Sample.find(params[:id])
    respond_with(@sample)
  end

  def edit
    @sample = Sample.find(params[:id])
    respond_with(@sample)
  end

  def update
    @sample = Sample.find(params[:id])
    update_sample_with_params
    flash[:notice] = 'The sample was successfully updated.' if @sample.save
    respond_with(@sample)
  end

  def destroy
    @sample = Sample.find(params[:id])
    if @sample.can_delete? && @sample.destroy
      flash[:notice] = 'The sample was successfully deleted.'
    else
      flash[:notice] = 'It was not possible to delete the sample.'
    end
    respond_with(@sample, location: root_path)
  end

  # called from AJAX, returns the form containing the attributes for the sample_type_id
  def attribute_form
    sample_type_id = params[:sample_type_id]

    sample = Sample.new(sample_type_id: sample_type_id)

    respond_with do |format|
      format.js do
        render json: {
          form: (render_to_string(partial: 'samples/sample_attributes_form', locals: { sample: sample }))
        }
      end
    end
  end

  def filter
    @associated_samples = params[:assay_id].blank? ? [] : Assay.find(params[:assay_id]).samples
    @samples = Sample.where('title LIKE ?', "%#{params[:filter]}%").limit(20)

    respond_with do |format|
      format.html do
        render partial: 'samples/association_preview', collection: @samples,
               locals: { existing: @associated_samples }
      end
    end
  end

  private

  def update_sample_with_params
    @sample.update_attributes(params[:sample])
    update_sharing_policies @sample, params
    update_annotations(params[:tag_list], @sample)
    update_relationships(@sample, params)
  end

  def find_index_assets
    if params[:data_file_id]
      @data_file = DataFile.find(params[:data_file_id])

      unless @data_file.can_view?
        flash[:error] = 'You are not authorize to view samples from this data file'
        respond_to do |format|
          format.html { redirect_to data_file_path(@data_file) }
        end
      end

      @samples = Sample.authorize_asset_collection(@data_file.extracted_samples.includes(sample_type: :sample_attributes).all, 'view')
    elsif params[:sample_type_id]
      @sample_type = SampleType.includes(:sample_attributes).find(params[:sample_type_id])
      @samples = Sample.authorize_asset_collection(@sample_type.samples.all, 'view')
    else
      find_assets
    end
  end
end
