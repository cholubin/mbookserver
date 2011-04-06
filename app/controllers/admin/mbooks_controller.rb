# encoding: utf-8
class Admin::MbooksController < ApplicationController
  layout 'admin_layout'
  before_filter :authenticate_admin!

  def index
    @board = "mbook"
    @section = "index"

    
    
    if params[:st] != "all" and params[:st] != "" and params[:st] != nil
      if params[:st] == "승인대기"
        @menu_on = "mb_req"
      elsif params[:st] == "삭제대기"
        @menu_on = "mb_del"
      else
        @menu_on = "mb_all"
      end
    else
      @menu_on = "mb_all"
    end
    
    @mbooks = Mbook.all

    if params[:st] != "all" and params[:st] != "" and params[:st] != nil
      @mbooks = @mbooks.all(:status => params[:st])
    end 
    @mbooks = @mbooks.search(params[:keyword], params[:search], params[:page])
    @total_count = @mbooks.search(params[:keyword], params[:search],"").count
    
    @categories = Category.all(:gubun => "template", :order => :priority)
     
    render 'mbook'
  end

  # GET /admin_mbooks/1
  # GET /admin_mbooks/1.xml
  def show
    @mbook = Admin::Mbook.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @mbook }
    end
  end

  # GET /admin_mbooks/new
  # GET /admin_mbooks/new.xml
  def new
    @mbook = Admin::Mbook.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @mbook }
    end
  end

  # GET /admin_mbooks/1/edit
  def edit
    @mbook = Admin::Mbook.find(params[:id])
  end

  # POST /admin_mbooks
  # POST /admin_mbooks.xml
  def create
    @mbook = Admin::Mbook.new(params[:mbook])

    respond_to do |format|
      if @mbook.save
        flash[:notice] = 'Admin::Mbook was successfully created.'
        format.html { redirect_to(@mbook) }
        format.xml  { render :xml => @mbook, :status => :created, :location => @mbook }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @mbook.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /admin_mbooks/1
  # PUT /admin_mbooks/1.xml
  def update
    @mbook = Admin::Mbook.find(params[:id])

    respond_to do |format|
      if @mbook.update_attributes(params[:mbook])
        flash[:notice] = 'Admin::Mbook was successfully updated.'
        format.html { redirect_to(@mbook) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @mbook.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /admin_mbooks/1
  # DELETE /admin_mbooks/1.xml
  def destroy
    @mbook = Admin::Mbook.find(params[:id])
    @mbook.destroy

    respond_to do |format|
      format.html { redirect_to(admin_mbooks_url) }
      format.xml  { head :ok }
    end
  end
end
