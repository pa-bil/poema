class RoleIdValidator < ActiveModel::Validator
  def validate(record)
    attr = record.attributes.select{|a,v| !(a =~ /granted_/).nil? && !v.nil?}
    if !attr.empty?
      attr.each do |elem|
        raise "Malformed attribute/value pair, please investigate" if elem.count != 2
        field = elem[0]
        role_id = elem[1]
        if Role.where({:id => role_id, :authorizable_type => nil, :authorizable_id => nil}).count != 1
          record.errors.add(field, :not_found)
        end
      end
    end
  end
end
