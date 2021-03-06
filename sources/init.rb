#anything that needs to be done before the rest of MangaScrap is executed is placed here

class Init
  def self.get_gem_list
    %w(singleton
  open-uri
  pp
  colorize
  nokogiri
  sqlite3
  typhoeus)
  end

  def self.get_file_list
    %w(scan/scan
  scan/scan_utils
  api/mangas
  api/other
  api/output
  api/params
  instructions/delete_diff
  instructions/redl
  utils/utils_file
  utils/utils_errors
  utils/utils_co
  utils/utils_db
  utils/utils_misc
  utils/utils_html
  utils/utils_debug
  utils/utils_user_input
  html/html
  html/html_manga
  Download/base_downloader
  Download/fanfox
  Download/mangareader_mangapanda
  DownloadDisplay
  instructions/Parsers/exec/Instruction_parser
  instructions/Parsers/exec/Data_parser
  instructions/Parsers/Query_Parser
  instructions/Parsers/File_parser
  instructions/Parsers/Site_parser
  instructions/query
  instructions/Instructions_exec
  instructions/Manga_data_filter
  Enums/download_types
  exceptions/Connection_exception
  DB/sub_data/data_module
  DB/sub_data/History
  DB/sub_data/Macro
  DB/sub_params/params_module
  DB/sub_params/HTML
  DB/sub_params/Download
  DB/sub_params/Misc
  DB/sub_params/Threads
  DB/manga_data/Manga_data
  DB/manga_data/Web_data
  DB/Params
  DB/Manga_database)
  end

  def self.load_gem(gem)
    begin
      require gem
    rescue Exception => e
      puts ''
      puts "exception while trying to load #{gem}, please follow the installation instructions in the install directory"
      puts 'message is : ' + e.message
      puts ''
      puts 'please note that a ruby update may require a re-download of the gems'
      puts ''
      exit 1
    end
  end

  def self.load_all_gems
    get_gem_list.each do |gem|
      load_gem gem
    end
  end

  def self.load_relative_files
    get_file_list.each do |file|
      require_relative file
    end
  end

  def self.init_structures
    Struct.new('Arg', :name, :sub_args, :nb_args, :does_not_need_args?)
    Struct.new('Sub_arg', :name, :nb_args)
    Struct.new('Updated', :name, :downloaded)
    Struct.new('Query_arg', :name, :arg_type, :sql_column, :sub_string)
    Struct.new('HTML_data', :volume, :chapter, :date, :href, :nb_pages, :file_name)
    Struct.new('Data', :volume, :chapter, :page, :link)
    Struct.new('Todo_value', :id, :manga_id, :volume, :chapter, :page, :date)
    Struct.new('Param_value', :string, :id, :type, :value, :class, :min_value, :max_value)
    Struct.new('Website', :link, :aliases, :dir, :to_complete, :class, :index_link_ends_with_slash)
    Struct.new('Manga_data_values', :name, :link, :id, :status, :website, :data, :download_class, :in_db, :index_page)
    Struct.new('Download_display_ref', :total_failed_pages, :failed, :total_pages, :pages, :downloaded_page)
    Struct.new('Connection_error', :link, :message, :nb_tries, :silent, :http_code, :error_code)
  end

  def self.initialize_mangascrap
    load_all_gems
    load_relative_files
    init_structures
    begin
      Utils_file::dir_create(Dir.home + '/.MangaScrap/db')
    rescue StandardError => error
      puts 'error while initializing MangaScrap'
      puts "error message is : '" + error.message + "'"
      exit 5
    end
    Utils_connection::init_utils
    unless Params.instance.misc[:color_text]
      String.disable_colorization = true
    end
  end
end
