

class V2::DecisionTableSerializer < V2::BaseSerializer
    #record_type :decision_table

    attributes :in_headers
    attributes :out_headers
    attributes :content
end