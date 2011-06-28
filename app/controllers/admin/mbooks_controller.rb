# encoding: utf-8
class Admin::MbooksController < ApplicationController
  layout 'admin_layout'
  before_filter :authenticate_admin!

  def index
    @board = "mbook"
    @section = "index"
    
    @mbooks = Mbook.all(:id => 00)
    
    if params[:sid] != nil and params[:sid] != ""
      @c_sid = params[:sid].to_i
    else
      @c_sid = 0
    end
    
    if @c_sid != 0 
      @c_pid = Category.get(@c_sid).parent_id
    else
      @c_pid = 0
    end
    
    if params[:lv] != nil and params[:lv] != ""
      @level = params[:lv].to_i
    else
      @level = 0
    end
    
    
    if params[:st] != "all" and params[:st] != "" and params[:st] != nil
      if params[:st] == "1"
        status = "승인대기"
      elsif params[:st] == "2"
        status = "삭제대기"
      elsif params[:st] == "3"
        status = "대기"
      elsif params[:st] == "4"
        status = "승인완료"
      else
        @menu_on = "mb_all"
      end
    end
    
    if params[:menu] != nil and params[:menu] != ""
      @menu_on = "mb_" + params[:menu]
    else
      @menu_on = "mb_all"
    end
    
    @pid = []
    @pid_temp = []
    @sid = []
    @sid_temp = []
    
    if @level == 0
        @pid_temp << @c_pid
        @pid_temp << @c_sid
        
        @sid_temp << @c_sid
        @sid_temp << 0
    else
      pid = 0
      sid = 0
      @pid_temp << @c_sid
      @sid_temp << 0
      
      (@level).downto(0) { |x|
        if @level == x
          @pid_temp << @c_pid
          pid = Category.get(@c_pid).parent_id if Category.get(@c_pid) != nil

          @sid_temp << @c_sid
          sid = Category.get(@c_sid).parent_id if Category.get(@c_sid) != nil
          
          # puts_message "current pid: " + pid.to_s
          # puts_message "current sid: " + sid.to_s
        else
          if x == 0
            @pid_temp <<  0
            
            @sid_temp << sid
          else
            @pid_temp << pid
            pid = Category.get(pid).parent_id if Category.get(pid) != nil
            
            @sid_temp << sid
            sid = Category.get(sid).parent_id
          end
          
        end
      }
    end
    
    if @level < 1
      @pid = @pid_temp
    else
      i = @pid_temp.length() -1
      puts_message "pid 갯수"+i.to_s
      @pid_temp.each do |x|
        @pid[i] = x
        i = i -1
      end
    end
    
    if @level < 1
      @sid = @sid_temp
    else
      i = @sid_temp.length() -1
      puts_message "sid 갯수"+i.to_s
      @sid_temp.each do |x|
        @sid[i] = x
        i = i -1
      end
      
    end
    
    
    @mbooks = get_mbooks(@mbooks, @c_sid)

    if params[:user] != nil and params[:user] != ""
      @mbooks = @mbooks.all(:user_id => params[:user].to_i)
    end
    
    if params[:st] != "all" and params[:st] != "" and params[:st] != nil
      @mbooks = @mbooks.all(:status => status)
    end 
    
    # if @c_sid != 0
    #   @mbooks = @mbooks.all(:subcategory1_id => @c_sid)
    # end

    mbooks = @mbooks
    
    @mbooks = @mbooks.search(mbooks, params[:keyword], params[:search], params[:page])
    @total_count = @mbooks.search(mbooks, params[:keyword], params[:search],"").count
    
    @categories = Category.all(:gubun => "template", :order => :priority)
     
    render 'mbook'
  end

  def get_mbooks(mbooks, current_id)
    @mbooks = mbooks
    
    # puts_message "id: "+ current_id.to_s + " // " + Mbook.all(:subcategory1_id => current_id).count.to_s
    @mbooks = @mbooks + ( Mbook.all(:subcategory1_id => current_id) || Mbook.all(:subcategory2_id => current_id) )
    puts_message @mbooks.count.to_s
    if Category.all(:parent_id => current_id).count > 0
      Category.all(:parent_id => current_id).each do |cat|
        @mbooks = get_mbooks(@mbooks, cat.id)
      end
      
      return @mbooks
    else
      return @mbooks
    end
  end
  
  # GET /admin_mbooks/1
  # GET /admin_mbooks/1.xml
  def show
    @mbook = Mbook.get(params[:id])
    
    if @mbook != nil
      @board = "mbook"
      @section = "show"
      
      @menu_on = params[:menu_on]
      
      @categories = Category.all(:gubun => "template", :order => :priority, :display_fl => true, :level => 0)
      
      render 'mbook'  
    else  
      redirect_to '/admin/mbooks'
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

  def deleteSelection 

    chk_ids = params[:ids]
    chks = chk_ids.split(",")

    chks.each do |chk|
      mbook = Mbook.get(chk.to_i)
      if mbook != nil
          puts_message mbook.zipfile
          if File.exists?(mbook.zipfile)
            FileUtils.rm_rf mbook.zipfile
          end
          
          puts_message mbook.zip_path
          if File.exists?(mbook.zip_path)
            FileUtils.rm_rf mbook.zip_path
          end
          
          puts_message MBOOK_PATH + mbook.id.to_s + ".zip"
          if File.exists?(MBOOK_PATH + mbook.id.to_s + ".zip")
            FileUtils.rm_rf MBOOK_PATH + mbook.id.to_s + ".zip"
          end
          
          mbook_id = mbook.id
          if mbook.destroy 
            puts_message "mBook ("+mbook_id.to_s+") 삭제 성공"
          else
            puts_message "mBook ("+mbook_id.to_s+") 삭제 실패"
          end
      end    
    end

    render :text => "success"
  end

  def change_status
    chk_ids = params[:ids]
    chks = chk_ids.split(",")

    chks.each do |chk|
      mbook = Mbook.get(chk.to_i)
      if mbook != nil
          
          mbook_id = mbook.id
          mbook.status = params[:str_status]
          if mbook.save 
            puts_message "mBook ("+mbook_id.to_s+") 상태변경 성공"
          else
            puts_message "mBook ("+mbook_id.to_s+") 상태변경 실패"
          end
      end    
    end

    render :text => "success"
  end
  
  #1개의 mBook파일에 대한 상태 변경 
  def update_status
    id = params[:id].to_i
    mode = params[:mode]
    
    if Mbook.get(id) != nil
      mbook = Mbook.get(id)
      mbook_id = mbook.id
      mbook.status = params[:str_status]
      if params[:mode] != "승인"
        mbook.cancel_reason = params[:cancel_reason]
      end
      
      if mbook.save 
        puts_message "mBook ("+mbook_id.to_s+") 상태변경 성공"
      else
        puts_message "mBook ("+mbook_id.to_s+") 상태변경 실패"
      end
    else
      redirect_to '/admin/mbooks'
    end

    render :text => "success"
  end
  
end
