

class V2::DecisionTableSerializer < V2::BaseSerializer
    #record_type :decision_table
    attributes :name
    attributes :start_period
    attributes :end_period
    attributes :in_headers
    attributes :out_headers
    attributes :content
    attributes :source_url
    attributes :comment
end