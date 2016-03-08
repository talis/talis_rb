class Object
  def blank?
    subject = respond_to?(:trim) ? strip : self
    subject.respond_to?(:empty?) ? subject.empty? : !subject
  end

  def present?
    !blank?
  end
end
