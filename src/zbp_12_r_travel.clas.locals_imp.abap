CLASS lhc_travelitem DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS validateFlightDate FOR VALIDATE ON SAVE
      IMPORTING keys FOR TravelItem~validateFlightDate.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR TravelItem RESULT result.
    METHODS determinetraveldates FOR DETERMINE ON SAVE
      IMPORTING keys FOR travelitem~determinetraveldates.

ENDCLASS.

CLASS lhc_travelitem IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD validateFlightDate.

    CONSTANTS: c_area TYPE string VALUE 'FL_DATE'.
    READ ENTITIES OF z12_r_travel IN LOCAL MODE
         ENTITY TravelItem FIELDS ( FlightDate AgencyId TravelId )
         WITH CORRESPONDING #( keys )
         RESULT DATA(travel_items).
    LOOP AT travel_items ASSIGNING FIELD-SYMBOL(<travel_item>).

      APPEND VALUE #( %tky = <travel_item>-%tky %state_area = c_area ) TO reported-travelitem
            ASSIGNING FIELD-SYMBOL(<result>).

      IF <travel_item>-FlightDate IS INITIAL.
        "This is just to return the failed key
        APPEND CORRESPONDING #( <travel_item> ) TO failed-travelitem.

        "This will return the failed field
        <result>-%msg = NEW /lrn/cm_s4d437( /lrn/cm_s4d437=>field_empty ).
        <result>-%element-flightdate = if_abap_behv=>mk-on.
        <result>-%path-travel = CORRESPONDING #( <travel_item> ).

      ELSEIF <travel_item>-FlightDate < cl_abap_context_info=>get_system_date( ).
        "This is just to return the failed key
        APPEND CORRESPONDING #( <travel_item> ) TO failed-travelitem.

        "This will return the failed field
        <result>-%msg = NEW /lrn/cm_s4d437( textid     = /lrn/cm_s4d437=>flight_date_past
                                            flightdate = <travel_item>-FlightDate ).
        <result>-%path-travel = CORRESPONDING #( <travel_item> ).
        <result>-%element-flightdate = if_abap_behv=>mk-on.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.



  METHOD determineTravelDates.

    CONSTANTS: c_area TYPE string VALUE 'FL_DATE'.
    READ ENTITIES OF z12_r_travel IN LOCAL MODE
         ENTITY TravelItem FIELDS ( FlightDate )
         WITH CORRESPONDING #( keys )
         RESULT DATA(travel_items)
         BY \_Travel FIELDS ( BeginDate EndDate )
         WITH CORRESPONDING #( keys )
         RESULT DATA(travels)
         LINK DATA(links).
    LOOP AT travel_items ASSIGNING FIELD-SYMBOL(<item>).
*      APPEND INITIAL LINE TO reported-travelitem ASSIGNING FIELD-SYMBOL(<report_item>).
      ASSIGN travels[ KEY id %tky = links[ KEY id source-%tky = <item>-%tky ]-target-%tky ] TO FIELD-SYMBOL(<travel>).

      IF <travel>-EndDate < <item>-FlightDate.
        <travel>-EndDate = <item>-FlightDate.
      ENDIF.

      IF <travel>-BeginDate > <item>-FlightDate AND <item>-FlightDate > cl_abap_context_info=>get_system_date(  ).
        <travel>-BeginDate = <item>-FlightDate.
      ENDIF.

    ENDLOOP.

    MODIFY ENTITIES OF z12_r_travel IN LOCAL MODE
    ENTITY Travel
    UPDATE FIELDS ( BeginDate EndDate )
    WITH CORRESPONDING #( travels ).
*
*      APPEND VALUE #( %tky = <travel_item>-%tky %state_area = c_area ) TO reported-travelitem
*            ASSIGNING FIELD-SYMBOL(<result>).
*
*      IF <travel_item>-FlightDate IS INITIAL.
*        "This is just to return the failed key
*        APPEND CORRESPONDING #( <travel_item> ) TO failed-travelitem.
*
*        "This will return the failed field
*        <result>-%msg = NEW /lrn/cm_s4d437( /lrn/cm_s4d437=>field_empty ).
*        <result>-%element-flightdate = if_abap_behv=>mk-on.
*        <result>-%path-travel = CORRESPONDING #( <travel_item> ).
*
*      ELSEIF <travel_item>-FlightDate < cl_abap_context_info=>get_system_date( ).
*        "This is just to return the failed key
*        APPEND CORRESPONDING #( <travel_item> ) TO failed-travelitem.
*
*        "This will return the failed field
*        <result>-%msg = NEW /lrn/cm_s4d437( textid     = /lrn/cm_s4d437=>flight_date_past
*                                            flightdate = <travel_item>-FlightDate ).
*        <result>-%path-travel = CORRESPONDING #( <travel_item> ).
*        <result>-%element-flightdate = if_abap_behv=>mk-on.
*      ENDIF.
*    ENDLOOP.

  ENDMETHOD.

ENDCLASS.

CLASS lhc_travel_saver DEFINITION INHERITING FROM cl_abap_behavior_saver.

  PROTECTED SECTION.

    METHODS adjust_numbers REDEFINITION.

    METHODS save_modified REDEFINITION.

    METHODS map_message IMPORTING i_msg        TYPE symsg
                        RETURNING VALUE(r_msg) TYPE REF TO if_abap_behv_message.

ENDCLASS.

CLASS lhc_travel_saver IMPLEMENTATION.

  METHOD adjust_numbers.
    DATA(agencyid) = /lrn/cl_s4d437_model=>get_agency_by_user( sy-uname ).
    LOOP AT mapped-travel ASSIGNING FIELD-SYMBOL(<travel>).
      <travel>-AgencyId = agencyid.
      <travel>-TravelId = /lrn/cl_s4d437_model=>get_next_travelid(  ).
    ENDLOOP.
  ENDMETHOD.

  METHOD save_modified.
    DATA(model) = NEW /lrn/cl_s4d437_tritem( i_table_name = 'z12_tritem' ).

    LOOP AT delete-travelitem ASSIGNING FIELD-SYMBOL(<ITEM_d>).
      DATA(msg_d) = model->delete_item( i_uuid = <item_d>-ItemUuid ).
      IF msg_d IS NOT INITIAL.
        APPEND VALUE #( %tky-ItemUuid = <item_d>-ItemUuid
                        %msg          = map_message( msg_d ) ) TO reported-travelitem.
      ENDIF.
    ENDLOOP.

    LOOP AT create-travelitem ASSIGNING FIELD-SYMBOL(<item_c>).
*      model->create_item( i_item = CORRESPONDING #( <item_c> MAPPING  agency_id            = AgencyId
*                                                                      booking_id           = BookingId
*                                                                      carrier_id           = CarrierId
*                                                                      changed_at           = ChangedAt
*                                                                      changed_by           = ChangedBy
*                                                                      connection_id        = ConnectionId
*                                                                      flight_date          = FlightDate
*                                                                      loc_changed_at       = LocChangedAt
*                                                                      passenger_first_name = PassengerFirstName
*                                                                      passenger_last_name  = PassengerLastName
*                                                                      travel_id            = TravelId
*                                                                      item_uuid            = ItemUuid ) ).
      DATA(msg_c) = model->create_item( i_item = CORRESPONDING #( <item_c> MAPPING FROM ENTITY ) ). "This will read the mapping from the bahavior
      IF msg_c IS NOT INITIAL.
        APPEND VALUE #( %tky-ItemUuid = <item_c>-ItemUuid
                        %msg          = map_message( msg_c ) ) TO reported-travelitem.
      ENDIF.

      IF create-travel IS NOT INITIAL.

        RAISE ENTITY EVENT z12_r_travel~travelCreated
            FROM CORRESPONDING #( create-travel ).

      ENDIF.

    ENDLOOP.

    LOOP AT update-travelitem ASSIGNING FIELD-SYMBOL(<item_u>).
      DATA(msg_u) = model->update_item( i_item  = CORRESPONDING #( <item_u> MAPPING FROM ENTITY )
                                        i_itemx = CORRESPONDING #( <item_u> MAPPING FROM ENTITY USING CONTROL ) ).
      IF msg_u IS NOT INITIAL.
        APPEND VALUE #( %tky-ItemUuid = <item_u>-ItemUuid
                        %msg          = map_message( msg_u ) ) TO reported-travelitem.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD map_message.
    r_msg = new_message(
    id       = i_msg-msgid
    number   = i_msg-msgno
    severity = SWITCH #( i_msg-msgty
                         WHEN 'E' THEN if_abap_behv_message=>severity-error
                         WHEN 'W' THEN if_abap_behv_message=>severity-warning
                         WHEN 'I' THEN if_abap_behv_message=>severity-information
                         WHEN 'S' THEN if_abap_behv_message=>severity-success
                         ELSE if_abap_behv_message=>severity-none )
    v1       = i_msg-msgv1
    v2       = i_msg-msgv2
    v3       = i_msg-msgv3
    v4       = i_msg-msgv4 ).
  ENDMETHOD.

ENDCLASS.

CLASS lhc_travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    CONSTANTS: BEGIN OF status,
                 cancel TYPE z12_r_travel-Status VALUE 'C',
                 new    TYPE z12_r_travel-Status VALUE 'N',
               END OF status.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR travel RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR travel RESULT result.

    METHODS cancel_travel FOR MODIFY
      IMPORTING keys FOR ACTION travel~cancel_travel.

    METHODS validatedescription FOR VALIDATE ON SAVE
      IMPORTING keys FOR travel~validatedescription.

    METHODS validatecustomer FOR VALIDATE ON SAVE
      IMPORTING keys FOR travel~validatecustomer.

    METHODS validatebegindate FOR VALIDATE ON SAVE
      IMPORTING keys FOR travel~validatebegindate.

    METHODS validateenddate FOR VALIDATE ON SAVE
      IMPORTING keys FOR travel~validateenddate.

    METHODS validatesequence FOR VALIDATE ON SAVE
      IMPORTING keys FOR travel~validatesequence.

    METHODS determinestatus FOR DETERMINE ON MODIFY
      IMPORTING keys FOR travel~determinestatus.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR travel RESULT result.
    METHODS determineduration FOR DETERMINE ON SAVE
      IMPORTING keys FOR travel~determineduration.
*    METHODS earlynumbering_create FOR NUMBERING
*      IMPORTING entities FOR CREATE travel.
ENDCLASS.

CLASS lhc_travel IMPLEMENTATION.

  METHOD get_instance_authorizations.

    result = CORRESPONDING #( keys ).

    LOOP AT result ASSIGNING FIELD-SYMBOL(<result>) WHERE AgencyId IS NOT INITIAL.
      DATA(auth) = /lrn/cl_s4d437_model=>authority_check(
                      i_agencyid = <result>-AgencyId
                      i_actvt    = '02' ).
      IF auth <> 0.
        <result>-%action-cancel_travel = if_abap_behv=>auth-unauthorized.
        <result>-%update               = if_abap_behv=>auth-unauthorized.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD cancel_travel.



    READ ENTITIES OF z12_r_travel IN LOCAL MODE
      ENTITY Travel ALL FIELDS
      WITH CORRESPONDING #( keys )
      RESULT DATA(travels)
      FAILED failed.

    IF failed IS INITIAL.
      LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).
        IF <travel>-Status <> status-cancel.

          MODIFY ENTITIES OF z12_r_travel IN LOCAL MODE
              ENTITY Travel
              UPDATE FIELDS ( Status )
              WITH VALUE #( ( %tky   = <travel>-%tky
                              Status = status-cancel ) ).

        ELSE. "In case already cancelled add a error message

          APPEND VALUE #( %tky = <travel>-%tky )
            TO failed-travel.

          APPEND VALUE #( %tky = <travel>-%tky
                          %msg = NEW /lrn/cm_s4d437( textid = /lrn/cm_s4d437=>already_canceled ) )
            TO reported-travel.

        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.

  METHOD validateDescription.
    CONSTANTS: c_area TYPE string VALUE 'DESC'.
    READ ENTITIES OF z12_r_travel IN LOCAL MODE
      ENTITY Travel FIELDS ( Description )
      WITH CORRESPONDING #( keys )
      RESULT DATA(travels).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).

      APPEND VALUE #( %tky = <travel>-%tky %state_area = c_area ) TO reported-travel
          ASSIGNING FIELD-SYMBOL(<result>).

      IF <travel>-Description IS INITIAL.
        "This is just to return the failed key
        APPEND CORRESPONDING #( <travel> ) TO failed-travel.

        "This will return the failed field
        <result>-%msg                 = NEW /lrn/cm_s4d437( /lrn/cm_s4d437=>field_empty ).
        <result>-%element-description = if_abap_behv=>mk-on.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateCustomer.
    CONSTANTS: c_area TYPE string VALUE 'CUST'.
    READ ENTITIES OF z12_r_travel IN LOCAL MODE
       ENTITY Travel FIELDS ( CustomerId )
       WITH CORRESPONDING #( keys )
       RESULT DATA(travels).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).

      APPEND VALUE #( %tky = <travel>-%tky %state_area = c_area ) TO reported-travel
          ASSIGNING FIELD-SYMBOL(<result>).

      IF <travel>-CustomerId IS INITIAL.
        "This is just to return the failed key
        APPEND CORRESPONDING #( <travel> ) TO failed-travel.

        "This will return the failed field
        <result>-%msg                = NEW /lrn/cm_s4d437( /lrn/cm_s4d437=>field_empty ).
        <result>-%element-customerid = if_abap_behv=>mk-on.

      ELSE.

        SELECT SINGLE
          FROM /DMO/I_Customer
        FIELDS CustomerID
         WHERE CustomerID = @<travel>-CustomerId
          INTO @DATA(customer).
        IF sy-subrc <> 0.
          "This is just to return the failed key
          APPEND CORRESPONDING #( <travel> ) TO failed-travel.

          "This will return the failed field
          <result>-%element-customerid = if_abap_behv=>mk-on.
          <result>-%msg                = NEW /lrn/cm_s4d437( textid     = /lrn/cm_s4d437=>customer_not_exist
                                                             customerid = <travel>-CustomerId ).
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateBeginDate.
    CONSTANTS: c_area TYPE string VALUE 'BEGIN_D'.
    READ ENTITIES OF z12_r_travel IN LOCAL MODE
         ENTITY Travel FIELDS ( BeginDate )
         WITH CORRESPONDING #( keys )
         RESULT DATA(travels).
    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).

      APPEND VALUE #( %tky = <travel>-%tky %state_area = c_area ) TO reported-travel
            ASSIGNING FIELD-SYMBOL(<result>).

      IF <travel>-BeginDate IS INITIAL.
        "This is just to return the failed key
        APPEND CORRESPONDING #( <travel> ) TO failed-travel.

        "This will return the failed field
        <result>-%msg = NEW /lrn/cm_s4d437( /lrn/cm_s4d437=>field_empty ).
        <result>-%element-begindate = if_abap_behv=>mk-on.

      ELSEIF <travel>-BeginDate < cl_abap_context_info=>get_system_date( ).
        "This is just to return the failed key
        APPEND CORRESPONDING #( <travel> ) TO failed-travel.

        "This will return the failed field
        <result>-%msg = NEW /lrn/cm_s4d437( textid    = /lrn/cm_s4d437=>begin_date_past
                                            begindate = <travel>-BeginDate ).
        <result>-%element-begindate = if_abap_behv=>mk-on.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateEndDate.
    CONSTANTS: c_area TYPE string VALUE 'END_D'.
    READ ENTITIES OF z12_r_travel IN LOCAL MODE
          ENTITY Travel FIELDS ( EndDate )
          WITH CORRESPONDING #( keys )
          RESULT DATA(travels).
    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).

      APPEND VALUE #( %tky = <travel>-%tky %state_area = c_area ) TO reported-travel
              ASSIGNING FIELD-SYMBOL(<result>).

      IF <travel>-EndDate IS INITIAL.
        "This is just to return the failed key
        APPEND CORRESPONDING #( <travel> ) TO failed-travel.

        "This will return the failed field
        <result>-%msg             = NEW /lrn/cm_s4d437( /lrn/cm_s4d437=>field_empty ).
        <result>-%element-EndDate = if_abap_behv=>mk-on.

      ELSEIF <travel>-EndDate < cl_abap_context_info=>get_system_date( ).
        "This is just to return the failed key
        APPEND CORRESPONDING #( <travel> ) TO failed-travel.

        "This will return the failed field
        <result>-%msg             = NEW /lrn/cm_s4d437( /lrn/cm_s4d437=>end_date_past ).
        <result>-%element-EndDate = if_abap_behv=>mk-on.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateSequence.
    CONSTANTS: c_area TYPE string VALUE 'SEQU'.
    READ ENTITIES OF z12_r_travel IN LOCAL MODE
            ENTITY Travel FIELDS ( BeginDate EndDate )
            WITH CORRESPONDING #( keys )
            RESULT DATA(travels).
    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).

      APPEND VALUE #( %tky        = <travel>-%tky
                      %state_area = c_area ) TO reported-travel ASSIGNING FIELD-SYMBOL(<result>).

      IF <travel>-EndDate < <travel>-BeginDate.
        "This is just to return the failed key
        APPEND CORRESPONDING #( <travel> ) TO failed-travel.

        "This will return the failed field
        <result>-%msg = NEW /lrn/cm_s4d437( /lrn/cm_s4d437=>dates_wrong_sequence ).
        <result>-%element-EndDate   = if_abap_behv=>mk-on.
        <result>-%element-BeginDate = if_abap_behv=>mk-on.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

*  METHOD earlynumbering_create.
*    DATA(agencyid) = /lrn/cl_s4d437_model=>get_agency_by_user( sy-uname ).
*    mapped-travel = CORRESPONDING #( entities ).
*    LOOP AT mapped-travel ASSIGNING FIELD-SYMBOL(<travel>).
*      <travel>-AgencyId = agencyid.
*      <travel>-TravelId = /lrn/cl_s4d437_model=>get_next_travelid(  ).
*    ENDLOOP.
*  ENDMETHOD.

  METHOD determineStatus.
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<travel>).
      MODIFY ENTITIES OF z12_r_travel IN LOCAL MODE
        ENTITY Travel UPDATE FIELDS ( Status )
        WITH VALUE #( ( %tky   = <travel>-%tky
                        Status = status-new ) )
        FAILED DATA(failed).
    ENDLOOP.
  ENDMETHOD.

  METHOD get_instance_features.

    READ ENTITIES OF z12_r_travel IN LOCAL MODE
     ENTITY Travel FIELDS ( BeginDate EndDate Status )
     WITH CORRESPONDING #( keys )
     RESULT DATA(travels).
    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).
      APPEND CORRESPONDING #( <travel> ) TO result
                ASSIGNING FIELD-SYMBOL(<result>).

      "Validations when Draft = TRUE
      IF <travel>-%is_draft = if_abap_behv=>mk-on.

        <result>-%action-cancel_travel = if_abap_behv=>fc-o-disabled.

        READ ENTITIES OF z12_r_travel IN LOCAL MODE
          ENTITY Travel
          FIELDS ( BeginDate EndDate )
          WITH VALUE #( ( %key = <travel>-%key ) )
          RESULT DATA(travels_actv).

        IF travels_actv IS NOT INITIAL AND line_exists( travels[ KEY entity %key = <travel>-%key ] ).
          DATA(travel_actv) = travels[ KEY entity %key = <travel>-%key ].
          <travel>-BeginDate = travel_actv-BeginDate.
          <travel>-EndDate   = travel_actv-EndDate.
        ELSE.
          CLEAR: <travel>-BeginDate, <travel>-EndDate.
        ENDIF.

      ENDIF.

      IF <travel>-Status    = status-cancel OR "If status is Cancelled
         ( <travel>-EndDate   IS NOT INITIAL                             AND "Or dates are already in the past
           <travel>-EndDate   < cl_abap_context_info=>get_system_date( ) AND
           <travel>-BeginDate IS NOT INITIAL AND
           <travel>-BeginDate < cl_abap_context_info=>get_system_date( ) ) .
        <result>-%update = <result>-%action-cancel_travel = if_abap_behv=>fc-o-disabled.
      ENDIF.

      IF <travel>-BeginDate IS NOT INITIAL AND <travel>-BeginDate < cl_abap_context_info=>get_system_date( ).
        <result>-%field-BeginDate = <result>-%field-CustomerId = if_abap_behv=>fc-f-read_only.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD determineDuration.
    READ ENTITIES OF z12_r_travel IN LOCAL MODE
          ENTITY Travel
          FIELDS ( BeginDate EndDate )
          WITH CORRESPONDING #( keys )
          RESULT DATA(travels).
    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>) WHERE EndDate IS NOT INITIAL
                                                       AND BeginDate IS NOT INITIAL.
      <travel>-DurationDays = <travel>-EndDate - <travel>-BeginDate.
    ENDLOOP.

    MODIFY ENTITIES OF z12_r_travel IN LOCAL MODE
        ENTITY Travel UPDATE
        FIELDS ( DurationDays )
        WITH CORRESPONDING #( travels )
        FAILED DATA(failed).

  ENDMETHOD.

ENDCLASS.
