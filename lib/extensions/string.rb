# encoding: utf-8
class String
   def to_underscore!
     self.gsub!(/(.)([A-Z])/,'\1_\2').downcase!
   end

   def to_underscore
     self.gsub(/(.)([A-Z])/,'\1_\2').downcase
   end
   
   def tr_pl_chars
     self.tr("ęóąśłżźćńĘÓĄŚŁŻŹĆŃ","eoaslzzcnEOASLZZCN")
   end

   def uncapitalize
     self[0, 1].downcase + self[1..-1]
   end
end
