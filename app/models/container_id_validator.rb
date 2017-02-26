class ContainerIdValidator < ActiveModel::Validator
  def validate(record)
    case record
      when Publication
        if record.container_id.nil? || Container.find_by_id(record.container_id).nil?
          record.errors.add(:container_id, "activerecord.errors.models.publication.attributes.container_id.missing" % record.container_id)
        end

      when Container
        if !record.new_record? && record.id == record.container_id
          record.errors.add(:container_id, "activerecord.errors.models.container.attributes.container_id.circular")
        end
        if record.container_id != nil && Container.find_by_id(record.container_id).nil?
          record.errors.add(:container_id, "activerecord.errors.models.container.attributes.container_id.missing" % record.container_id)
        end
    end
  end
end
