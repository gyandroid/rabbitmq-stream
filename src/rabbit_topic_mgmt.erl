-module(rabbit_topic_mgmt).

-behaviour(rabbit_mgmt_extension).

-export([dispatcher/0, web_ui/0]).
-export([init/1, to_json/2, resource_exists/2, content_types_provided/2,
         is_authorized/2]).

-import(rabbit_misc, [pget/2]).

-include_lib("rabbitmq_management/include/rabbit_mgmt.hrl").
-include_lib("webmachine/include/webmachine.hrl").

dispatcher() -> [{["topic-queues"],                  ?MODULE, []},
                 {["topic-queues", vhost],           ?MODULE, []},
                 {["topic-queues", vhost, exchange], ?MODULE, []].
web_ui()     -> [{javascript, <<"topic.js">>}]. %% No UI for now.

%%--------------------------------------------------------------------

init(_Config) -> {ok, #context{}}.

content_types_provided(ReqData, Context) ->
   {[{"application/json", to_json}], ReqData, Context}.

resource_exists(ReqData, Context) ->
    {case queues0(ReqData) of
         vhost_not_found -> false;
         _               -> true
     end, ReqData, Context}.

to_json(ReqData, Context) ->
    rabbit_mgmt_util:reply(queues0(ReqData), ReqData, Context).

is_authorized(ReqData, Context) ->
    rabbit_mgmt_util:is_authorized_vhost(ReqData, Context).

%%--------------------------------------------------------------------

queues0(ReqData) ->
    rabbit_mgmt_util:all_or_one_vhost(ReqData, fun rabbit_topic_util:list_queues_on_vhost/1).
        
        
exchange(ReqData) ->
    case rabbit_mgmt_util:vhost(ReqData) of
        not_found -> not_found;
        VHost     -> exchange(VHost, id(ReqData))
    end.

exchange(VHost, XName) ->
    Name = rabbit_misc:r(VHost, exchange, XName),
    case rabbit_exchange:lookup(Name) of
        {ok, X}            -> rabbit_mgmt_format:exchange(
                                rabbit_exchange:info(X));
        {error, not_found} -> not_found
    end.

id(ReqData) ->
    rabbit_mgmt_util:id(exchange, ReqData).