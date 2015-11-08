# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class ProfilesController < ApplicationController
  before_filter :login_required
  before_filter :set_title
  before_filter :set_cib
  before_filter :set_record, only: [:edit, :update]

  def edit
    respond_to do |format|
      format.html
    end
  end

  def update
    if params[:revert]
      return redirect_to edit_cib_profile_url(cib_id: @cib.id)
    end

    respond_to do |format|
      if @profile.update_attributes(params[:profile])
        post_process_for! @profile

        format.html do
          flash[:success] = _('Preferences updated successfully')
          redirect_to edit_cib_profile_url(cib_id: @cib.id)
        end
      else
        format.html do
          render action: 'edit'
        end
      end
    end
  end

  protected

  def set_title
    @title = _('Preferences')
  end

  def set_cib
    @cib = current_cib
  end

  def set_record
    @profile = Profile.new language: cookies[:locale]
  end

  def post_process_for!(record)
    locale = if record.language.to_s.empty?
      default_locale
    else
      record.language
    end.gsub("_", "-")

    cookies[:locale] = locale

    I18n.locale = FastGettext.set_locale(
      locale
    )
  end
end
