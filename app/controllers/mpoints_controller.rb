# encoding: utf-8
class MpointsController < ApplicationController
  before_filter :authenticate_user!  
  
  def index
    mode = params[:mode] != nil ? params[:mode] : nil
    
    @user_type = "writer"
    
    if mode == "ch"
      @page_type = "charge"
    else
      @page_type = "main"
      
      # MBook 판매 현황 ==============================================================================================================================
      limit_free_mbook_dn_cnt = Mbookdncount.all(:userid => current_user.id, :free_or_not_fl => true, :conditions => ["created_at between ? and ?", Time.now.to_datetime.beginning_of_month, Time.now.to_datetime.next_month.beginning_of_month]).count
      # puts_message Time.now.to_datetime.prev_month.beginning_of_month.to_s
      # puts_message  Time.now.to_datetime.next_month.beginning_of_month.to_s
      
      
      limit_not_free_mbook_dn_cnt = Mbookdncount.all(:userid => current_user.id, :free_or_not_fl => false, :conditions => ["created_at between ? and ?", Time.now.to_datetime.beginning_of_month, Time.now.to_datetime.next_month.beginning_of_month]).count
      
      unlimit_free_mbook_dn_cnt = Mbookdncount.all(:userid => current_user.id, :free_or_not_fl => true, :mbookid => Mbook.all(:unlimited_down_fl => true), :conditions => ["created_at between ? and ?", Time.now.to_datetime.beginning_of_month, Time.now.to_datetime.next_month.beginning_of_month]).count
      unlimit_not_free_mbook_dn_cnt = Mbookdncount.all(:userid => current_user.id, :free_or_not_fl => false, :mbookid => Mbook.all(:unlimited_down_fl => true), :conditions => ["created_at between ? and ?", Time.now.to_datetime.beginning_of_month, Time.now.to_datetime.next_month.beginning_of_month]).count
      
      totla_dn_cnt = limit_free_mbook_dn_cnt +limit_not_free_mbook_dn_cnt + unlimit_free_mbook_dn_cnt + unlimit_not_free_mbook_dn_cnt
      
      limit_free_mbook_dn_point = limit_free_mbook_dn_cnt * MDOWN_POINT
      limit_not_free_mbook_dn_point = limit_not_free_mbook_dn_cnt * MDOWN_POINT
      
      total_dn_point = limit_free_mbook_dn_point + limit_not_free_mbook_dn_point
      @selling_status = {"1"=>limit_free_mbook_dn_cnt,"2"=>limit_not_free_mbook_dn_cnt,"3"=>unlimit_free_mbook_dn_cnt,"4"=>unlimit_not_free_mbook_dn_cnt,"5"=>totla_dn_cnt,"6"=>limit_free_mbook_dn_point,"7"=>limit_not_free_mbook_dn_point, "8"=>total_dn_point}

      #포인트 현황 ======================================================================================================================================
      carry_over_point = 0
      charged_point = Mpoint.sum(:point, :account => "P01", :user_id => current_user.id, :conditions => ["created_at between ? and ?", Time.now.to_datetime.beginning_of_month, Time.now.to_datetime.next_month.beginning_of_month]).to_i
      bonus_point = Mpoint.sum(:point, :account => "P02", :user_id => current_user.id, :conditions => ["created_at between ? and ?", Time.now.to_datetime.beginning_of_month, Time.now.to_datetime.next_month.beginning_of_month]).to_i
      minus_point = Mpoint.sum(:point, :account => "M02", :user_id => current_user.id, :conditions => ["created_at between ? and ?", Time.now.to_datetime.beginning_of_month, Time.now.to_datetime.next_month.beginning_of_month]).to_i
      dn_minus_point = Mpoint.sum(:point, :account => "M01", :user_id => current_user.id, :conditions => ["created_at between ? and ?", Time.now.to_datetime.beginning_of_month, Time.now.to_datetime.next_month.beginning_of_month]).to_i
      total_left_point = (carry_over_point + charged_point + bonus_point) - (minus_point + dn_minus_point)

      @point_status = {"1"=>carry_over_point, "2"=>charged_point, "3"=>bonus_point, "4"=>minus_point,"5"=>dn_minus_point,"6"=>total_left_point}

      
      #HDD 현황 ======================================================================================================================================
      mbook_cnt = Mbook.all(:user_id => current_user.id).count
      mbook_filesize = 0.0
      
      if current_user.servicetype == "single"
        hdd_max = 5000
      elsif current_user.servicetype == "multiple"
        hdd_max = 10000
      else 
        hdd_max = 5000
      end
      
      @mbooks = Mbook.all(:user_id => current_user.id)
      
      @mbooks.each do |mbook|
        if File.exists?(mbook.zipfile)
          file_size = round_to(File.size(mbook.zipfile) / (1000.0 * 1000.0), 1)
        else
          file_size = 0.0
        end
        mbook_filesize += file_size
      end
      
      hdd_left = hdd_max - mbook_filesize
      
      @hdd_status = {"mbook_cnt" => mbook_cnt, "mbook_filesize" => mbook_filesize, "hdd_max" => hdd_max, "hdd_left" => hdd_left}
      
    end
    
    if current_user.servicetype == "shared"
      @service = "shared"
    else
      @service = "single"
    end
    
    @menu_on = "mpoint" 
    
    
    
    render 'mpoint'
  end
  
  def sales_history
    mbook_id = params[:mbook_id] == "all" ? "all":params[:mbook_id].to_i
    from_date = params[:from_date] == "" ? "":params[:from_date].gsub("-","").to_datetime.beginning_of_day 
    to_date = params[:to_date] == "" ? "":params[:to_date].gsub("-","").to_datetime.next_day.beginning_of_day 
    
    @mbookcounts = Mbookdncount.all(:userid => current_user.id)
    
    if mbook_id != "all"
      @mbookcounts = @mbookcounts.all(:mbookid => mbook_id)
    end
    
    if from_date != "" and to_date != ""
      @mbookcounts = @mbookcounts.all(:conditions => ["created_at between ? and ?", from_date, to_date])
    end
    
    limit_ipad_free_mbook_dn_cnt = @mbookcounts.all(:free_or_not_fl => true, :devicetype_main => "1").count
    limit_android_free_mbook_dn_cnt = @mbookcounts.all(:free_or_not_fl => true, :devicetype_main => "2").count
    
    
    limit_ipad_not_free_mbook_dn_cnt = @mbookcounts.all(:free_or_not_fl => false, :devicetype_main => "1").count
    limit_android_not_free_mbook_dn_cnt = @mbookcounts.all(:free_or_not_fl => false, :devicetype_main => "2").count
    
    
    unlimit_ipad_free_mbook_dn_cnt = @mbookcounts.all(:free_or_not_fl => true, :devicetype_main => "1", :mbookid => Mbook.all(:unlimited_down_fl => true)).count
    unlimit_android_free_mbook_dn_cnt = @mbookcounts.all(:free_or_not_fl => true, :devicetype_main => "2", :mbookid => Mbook.all(:unlimited_down_fl => true)).count
    
    unlimit_ipad_not_free_mbook_dn_cnt = @mbookcounts.all(:free_or_not_fl => false, :devicetype_main => "1", :mbookid => Mbook.all(:unlimited_down_fl => true)).count
    unlimit_android_not_free_mbook_dn_cnt = @mbookcounts.all(:free_or_not_fl => false, :devicetype_main => "2", :mbookid => Mbook.all(:unlimited_down_fl => true)).count
    
    sum_limit_free_dn_cnt = limit_ipad_free_mbook_dn_cnt + limit_android_free_mbook_dn_cnt
    sum_limit_not_free_dn_cnt = limit_ipad_not_free_mbook_dn_cnt + limit_android_not_free_mbook_dn_cnt
    sum_unlimit_free_dn_cnt = unlimit_ipad_free_mbook_dn_cnt + unlimit_android_free_mbook_dn_cnt
    sum_unlimit_not_free_dn_cnt = unlimit_ipad_not_free_mbook_dn_cnt + unlimit_android_not_free_mbook_dn_cnt
    
    sum_ipad_dn_cnt = limit_ipad_free_mbook_dn_cnt + limit_ipad_not_free_mbook_dn_cnt + unlimit_ipad_free_mbook_dn_cnt + unlimit_ipad_not_free_mbook_dn_cnt
    sum_android_dn_cnt = limit_android_free_mbook_dn_cnt + limit_android_not_free_mbook_dn_cnt + unlimit_android_free_mbook_dn_cnt + unlimit_android_not_free_mbook_dn_cnt
    sum_total_dn_cnt = sum_ipad_dn_cnt + sum_android_dn_cnt
    
    @sales_history_cnt = {"1-1"=>limit_ipad_free_mbook_dn_cnt, "1-2"=>limit_android_free_mbook_dn_cnt, "1-3"=>sum_limit_free_dn_cnt, "2-1"=>limit_ipad_not_free_mbook_dn_cnt, "2-2"=>limit_android_not_free_mbook_dn_cnt, "2-3"=>sum_limit_not_free_dn_cnt, "3-1"=>unlimit_ipad_free_mbook_dn_cnt, "3-2"=>unlimit_android_free_mbook_dn_cnt, "3-3"=>sum_unlimit_free_dn_cnt, "4-1"=>unlimit_ipad_not_free_mbook_dn_cnt, "4-2"=>unlimit_android_not_free_mbook_dn_cnt, "4-3"=>sum_unlimit_not_free_dn_cnt, "5-1"=>sum_ipad_dn_cnt, "5-2"=>sum_android_dn_cnt, "5-3"=>sum_total_dn_cnt}
    
    
    render :partial => 'sales_history_table_block', :object => @sales_history_cnt
  end
end