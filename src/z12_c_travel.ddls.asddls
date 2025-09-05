@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Flight Travel (Projection View)'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
@Search.searchable: true
define root view entity Z12_C_TRAVEL
  provider contract transactional_query
  as projection on Z12_R_TRAVEL
{
  key AgencyId,
  key TravelId,
      @Search: { defaultSearchElement: true,
                 fuzzinessThreshold: 0.8 }
      Description,
      @Search: { defaultSearchElement: true,
                 fuzzinessThreshold: 0.8 }
      @Consumption.valueHelpDefinition: [{ entity: { name: '/DMO/I_Customer_StdVH', element: 'CustomerID' } }]
      CustomerId,
      BeginDate,
      EndDate,
      Status,
      ChangedAt,
      ChangedBy,
      LastChangedAt,
      DurationDays,
      /* Associations */
      _TravelItem : redirected to composition child Z12_C_TRAVELITEM
}
