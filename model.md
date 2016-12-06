// Scorpio Diagram
[Users|id;name:string;email:string;password:string;project_id]
[Projects|id;name:string;dhis2_url;user:string;password:string;bypass_ssl:bool]
[EntityGroups|id;project_id;name:string;orgunitgroup:ext_ref]
[States|id;name:string;]++1-0..*>[PackageStates|id;state_id;package_id]
[PackageStates]++1..*-1>[Packages|id;project_id;name:string;dataeltgroup:ext_ref;frequency:string]
[Packages]++0..*-1>[PackageEntityGroups|id;package_id;name:string;orgunitgroup:ext_ref]

[EntityGroups]++1-1..*>[Projects]
[Packages]<1..*-1>[Projects]
[Users]<1..*-1>[Projects]
