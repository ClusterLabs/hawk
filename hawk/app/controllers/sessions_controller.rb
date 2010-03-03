class SessionsController < ApplicationController
  layout 'main'

  def initialize
    @title = _('Log In')
  end

  def index
    new
    return
  end

  def show
  end

  def new
    # render login screen
  end

  # called from login screen
  UNIX2_CHKPWD = '/sbin/unix2_chkpwd'
  def create
    if params[:username].blank?
      flash[:warning] = _('Username not specified')
      redirect_to :action => 'new'
    elsif params[:username].include?("'") || params[:username].include?("$")
      # No ' or $ characters, because this is going to the shell
      flash[:warning] = _('Invalid username')
      redirect_to :action => 'new'
    elsif params[:password].blank?
      flash[:warning] = _('Password not specified')
      redirect_to :action => 'new', :username => params[:username]
    else
      if File.exists?(UNIX2_CHKPWD) && File.executable?(UNIX2_CHKPWD)
        IO.popen("#{UNIX2_CHKPWD} passwd '#{params[:username]}'", 'w+') do |pipe|
          pipe.write params[:password]
          pipe.close_write
        end
        if $?.exitstatus == 0 && allow_group(params[:username])
          # The user can log in, and they're in our required group
          reset_session
          session[:username] = params[:username]
          redirect_back_or_default root_url
        else
          # No dice...
          flash[:warning] = _('Invalid username or password')
          redirect_to :action => 'new', :username => params[:username]
        end
      else
        flash[:warning] = _('%s is not installed') % UNIX2_CHKPWD
        redirect_to :action => 'new', :username => params[:username]
      end
    end
  end

  def destroy
    session[:username] = nil
    reset_session
    redirect_to :action => 'new'
  end

  # TODO: this needs to be build-time, not hard-coded
  ALLOW_GROUP = 'haclient'

  # Logic here is straight out of pygui /mgmt/daemon/mgmtd.c
  # (yeah, I know it reads ugly...)
  # TODO: exceptions
  private
  def allow_group(username)
    require 'etc'

    pwnam = Etc.getpwnam(username)
    return false unless pwnam

    grgid = Etc.getgrgid(pwnam.gid)
    return false unless grgid

    return true if grgid.name == ALLOW_GROUP

    grnam = Etc.getgrnam(ALLOW_GROUP)
    return false unless grnam

    return grnam.mem.include?(username)
  end
end
