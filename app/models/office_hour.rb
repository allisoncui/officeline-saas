class OfficeHour < ApplicationRecord
     def self.all_days
       %w[Monday Tuesday Wednesday Thursday Friday]
     end

     def self.with_filters(days, sort_by)
       if days.nil?
         all.order sort_by
       else
         where(day: days.map(&:capitalize)).order sort_by
       end
     end
   end