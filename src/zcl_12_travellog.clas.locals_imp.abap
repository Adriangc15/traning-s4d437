CLASS lhc_handler DEFINITION INHERITING FROM cl_abap_behavior_event_handler.
  PRIVATE SECTION.

    METHODS onTravelCreated FOR ENTITY EVENT
      IMPORTING i_created_travels
                  FOR travel~travelCreated.

ENDCLASS.

CLASS lhc_handler IMPLEMENTATION.

  METHOD ontravelcreated.
    DATA: logs TYPE TABLE FOR CREATE /LRN/437_I_TravelLog.

    LOOP AT i_created_travels ASSIGNING FIELD-SYMBOL(<travel_c>).

      APPEND VALUE #( agencyid = <travel_c>-AgencyId
                      travelid = <travel_c>-TravelId
                      origin   = 'Z12_R_TRAVEL' ) TO logs.

    ENDLOOP.

    MODIFY ENTITIES OF /LRN/437_I_TravelLog
        ENTITY TravelLog
        CREATE AUTO FILL CID
        FIELDS ( AgencyID TravelID Origin )
        WITH logs.

  ENDMETHOD.

ENDCLASS.
