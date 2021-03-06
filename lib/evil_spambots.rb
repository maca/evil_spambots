$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

module EvilSpambots
  extend self
  VERSION = '0.4.2'

  # String to ASCII html encoding that can be rendered correctly in browsers. eg: 
  #
  #     EvilSpambots.html_obfuscate("you can't readme") => '&#121;&#111;&#117;&#32;&#99;&#97;&#110;&#39;&#116;&#32;&#114;&#101;&#97;&#100;&#109;&#101;'
  # 
  # A block can be passed and it will be yielded passing the encoded character.
  #
  def html_obfuscate string
    return string.unpack('C*').collect{ |char| %{&##{ char };} }.join unless block_given?
    string.unpack('C*').collect{ |char| yield %{&##{ char };} }.join
  end

  # Obfuscate an email address so hopefully won't be harvested by evil spambots using javascript and ASCII html encoding with CSS techniques.
  #
  #     EvilSpambots.obfuscate_email('mail@example.com')
  # 
  # Will return:
  #
  #     <noscript>&#109;<span style="display: none;">&#109;</span>&#97;<span style="display: none;">&#97;</span>&#105;<span style="display: none;">&#105;</span>&#108;<span style="display: none;">&#108;</span>&#64;<span style="display: none;">&#64;</span>&#101;<span style="display: none;">&#101;</span>&#120;<span style="display: none;">&#120;</span>&#97;<span style="display: none;">&#97;</span>&#109;<span style="display: none;">&#109;</span>&#112;<span style="display: none;">&#112;</span>&#108;<span style="display: none;">&#108;</span>&#101;<span style="display: none;">&#101;</span>&#46;<span style="display: none;">&#46;</span>&#99;<span style="display: none;">&#99;</span>&#111;<span style="display: none;">&#111;</span>&#109;<span style="display: none;">&#109;</span></noscript>
  #       <script language='javascript'>
  #       <!--
  #         sequence = [190,333,159,217,365,262,225,162,282,243,319,231,156,173,190,264,81,153,247,270,312,202,139,274,130,121,180,266,42,197,221,282,63,116,183,141,238,295,71,116,39,214,54,237,275,137,125,245,135,175,256,122,102,289,157,138,152,143,130,240,157,105,254,259,69,258,72,73,162,252,272,127,239,247,278,238,290,160,214,157,286,50,166,155,91,181,227,60,91,228,240,136,280,153,114,261,139,169,112,207,276,43,59,107,228,155,121,113,97,262,160,129,195,250,196,143,269,101,157,284,112,206,208,225,85,105,78,204,117,53,299,290,101,288,94,178,279,102,180,264,88,244,81,180,87,159,180,62,278,173,186,242,96,112,219,156,197,123,227,211,51,286,100,133,121,281,142,77,227,57,274,114,117,228,199,128,264,275,274,95,64,273,167,128,288,263,206,252,125,217,69,73,173,106,41,174,105,164,178,212,89,137,98,297]
  #         codes    = [130,236,127,113,251,161,123,101,248,134,222,126,48,57,79,206,43,118,198,222,255,143,101,239,73,66,121,228,7,148,173,229,4,78,148,92,190,239,12,78,4,160,2,178,237,102,76,197,86,116,218,87,53,239,109,79,114,108,73,185,98,67,219,210,21,201,13,35,127,203,223,77,180,209,243,189,242,104,155,119,251,1,118,106,32,143,192,8,37,169,202,101,223,96,55,223,104,120,63,158,217,5,24,58,180,98,62,79,35,224,125,80,147,193,137,105,234,44,102,225,74,171,159,177,32,46,40,169,68,5,243,231,63,253,40,126,220,64,145,215,40,195,22,142,52,110,130,14,219,135,151,185,41,53,181,121,148,75,170,152,13,251,51,84,71,222,104,42,178,9,218,55,79,193,150,80,215,216,236,60,12,219,108,90,253,206,149,193,87,182,20,24,124,47,3,139,56,116,121,153,29,90,1,235]
  #         string   = ''
  #         for (c in sequence) {
  #           string += String.fromCharCode( sequence[c] - codes[c] );
  #         }
  #         document.write(string);
  #       //-->
  #     </script>
  #
  # Wich will in turn be rendered correctly with a browser with or without JavaScript
  #
  # Options:
  # * linktext: +String+
  #   The link inside the tag, defaults to the email address
  # * degradable: +true+ or +false+
  #   It true will html that renders correctly if the browser hasn't got JavaScript enabled.
  # 
  def obfuscate_email email, opts = {}
    linktext     = opts.delete(:linktext) || email
    degradable   = opts.key?(:degradable) ? opts.delete(:degradable) : true
    noscript     = %{<noscript>#{ html_obfuscate(linktext){ |c| c + '<span style="display: none;">'+ c +'</span>'} }</noscript>} if degradable
    sequence     = %{<a href="mailto:#{ html_obfuscate email }">#{ html_obfuscate linktext }</a>}.unpack('C*')
    codes        = Array.new(sequence.size){ rand(256).to_i }
    sequence     = sequence.zip(codes).map!{ |s, c| s + c }
    <<-HTML
    #{ noscript }
    <script language='javascript'>
    <!--
      sequence = [#{ sequence.join(',') }]
      codes    = [#{ codes.join(',') }]
      string   = ''
      for (c in sequence) {
        string += String.fromCharCode( sequence[c] - codes[c] );
      }
      document.write(string);
    //-->
    </script>
    HTML
  end
end

ActionView::Helpers::TextHelper.send(:include, EvilSpambots) rescue nil


