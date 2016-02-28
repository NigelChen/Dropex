
#init dependencies 
require 'zip'
#end dependencies

class PagesController < ApplicationController
  def index
    sweepFile
    
  end

  def sweepFile
    Defile.order(created_at: :desc).all.each do |f|
      if (DateTime.now.to_i - f.toDestroy.to_i) > 0
        puts "DELETE: " + f.name
        File.delete(Rails.root.join('public','files',f.maskedName + 'a.zip'))
        f.destroy
      elsif (not f.nil?) && f.maxlim <= f.downloads
        puts "DELETE: " + f.name
        File.delete(Rails.root.join('public','files',f.maskedName + 'a.zip'))
        f.destroy
      end
    end
  end
  
  def resetSettings
    cookies[:units] = 'min'
    cookies[:time] = '10'
    cookies[:interval] = '1'
    redirect_to "/"
  end
  
  def uploadFile
    if not verify_recaptcha
      flash[:notice] = "You need to complete the recaptcha."
      redirect_to "/"
    else
      fileObject = params[:upload][:file] #the file
      timeToDestroy = params[:upload][:time] #timer in (units)
      units = params[:upload][:units] #units of time. {'min','hours'}
      maxlim = params[:upload][:interval] #download limit
      code = params[:upload][:code] #custom code
      
      #checks the size of the file if the client side fails to.

      if fileObject.size >=52428801
        flash[:notice] = "File size is too large. Needs to be under 51MB."
        redirect_to "/"
      end
      
      #check the length of the code. handles accordingly
      if code.length <= 0
        code = randomCode()
        while not Defile.find_by_filecode(code).nil?
          code = randomCode()
        end
      end
      
      #checks the length of the download limit. handles accordingly
      if maxlim.length <=0
        if cookies[:interval]
          maxlim = cookies[:interval].to_i
        else
          maxlim = 1
        end
      end
      
      #checks the timer. handles accordingly
      if timeToDestroy.length <= 0
        if cookies[:time]
          timeToDestroy = cookies[:time].to_i
        else 
          timeToDestroy = 10
        end
      end
      
      timeToDestroy = timeToDestroy.to_i
      
      #checks the units of the cookies/website.
      if units == 'min' or (cookies[:units] == 'min')
        hours = DateTime.now + timeToDestroy.minutes
      else
        hours = DateTime.now + timeToDestroy.hours
      end
      
      
      #creates the file name.
      maskedFileName = SecureRandom.hex(3)
      while Defile.exists?(maskedFileName)
        maskedFileName = SecureRandom.hex(3)
      end
      
      #creates file object. save into databse
      Defile.create(name: fileObject.original_filename, maskedName: maskedFileName, toDestroy: hours, filecode: code,maxlim: maxlim,downloads:0)
      binaryCode = fileObject.read
      
      #saves the zip
      Zip::File.open(Rails.root.join('public','files',maskedFileName + 'a.zip'), Zip::File::CREATE) do |zipfile|
        zipfile.get_output_stream(fileObject.original_filename)  { |os| os.puts(binaryCode)}
      end
      
      flash[:success] = "Your file code is #{code} " 
      #yay, finished! redirect    
      redirect_to "/"
    end
  end
  
  def randomCode
    randomword = ""
  
    prng = Random.new
    filenum = prng.rand(1..5) #choose which word file
    prng2 = Random.new
    wordnum = prng2.rand(1..278) - 1 #choose line number from word file
       
    #get the random word
    File.open(Rails.root.join('public','words', filenum.to_s + '.txt'),'r') do |file|
      wordnum.times { file.gets }
      randomword = file.gets
    end

    return randomword.strip()
  end
  
  
  def downloadFile
    sweepFile
    fileName = params[:download][:code]
    if Defile.find_by_filecode(fileName).nil?
      flash[:notice] = "File code '#{fileName}' has not been found."
      redirect_to "/download"
    else
      Defile.update(Defile.find_by_filecode(fileName).id, downloads: Defile.find_by_filecode(fileName).downloads + 1)
      content = ""
      Zip::File.open(Rails.root.join('public','files',Defile.find_by_filecode(fileName).maskedName + 'a.zip')) do |zip|
        zip.each do |file|
          puts "OMFG I READING IT::::::"
          content = file.get_input_stream.read
        end
      end

      send_data(content, filename: Defile.find_by_filecode(fileName).name)
      
    end
  end
  
  '''
  START SETTINGS
  '''
  
  def configure
    time = params[:config][:time]
    units = params[:config][:units]
    interval = params[:config][:interval]
    cookies.permanent[:time] = time
    cookies.permanent[:units] = units
    cookies.permanent[:interval] = interval
    flash[:notice] = "Success. All configs are updated"
    redirect_to "/"
  end
  
end
