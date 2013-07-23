<br/><br/>


<div style='font-family:helvetica,arial;'>
    


  <hr style='width:800px;float:left'/>
  <br/>

  <h3><%= @command['page_header'] %></h3>
  <hr style='width:800px;float:left'/>
  <br/>

  <br/>
  <div id='command_header' style='background-color:lightgray;width:800px'>
    <table>
      <% @command['command_description'].each do |key,value| %>
        <tr>
          <td><strong><%=key%>: </strong></td>
          <td>        <%=value%>           </td>
        </tr>
      <% end %>
    </table>
    <hr style='width:800px;float:left'/>
    <br/>

  </div>



  
  <div id='current_state'  style='background-color:lightgreen;width:800px'>
    <table>
    <table border=1>
      <% @command['current_state'].each do |key,value| %>
        <tr>
          <td><strong><%=key%>:     </strong></td>
          <td>        <%=value%>           </td>
        </tr>
      <% end %>
    </table>
  </div>

    <hr style='width:800px;float:left'/>
    <br/>

  <br/>
    <hr style='width:800px;float:left'/>
    <br/>
  <br/>

  <div id='new_state' style=''>
 
   <div style='color:white;background-color:red;width:800px;float:left;font-size:10pt'>
      <% if @errors.empty? == false %>
        <% @errors.each do |key,value| %>
           <%=value%>
        <% end %>
      <% end %>


  </div>

  <form action="/process_command" method="post">
    
    <input type="hidden" name="command_class" value="<%=@command['command_class']%>"/> 
    <input type="hidden" name="aggregate_id" value="<%=@command['aggregate_id']%>"/> 
   <br/><br/>
    <table border=1>

      <% @command['new_state'].each do |key,value| %>
        <% field = key 
           label = value['label'] 
           html = value['html']
        %>

        <tr>
          <td><strong><%=label%>:     </strong></td>
          <td>        <%= set_form_field(field,html) %>           </td>
        </tr>
      <% end %>
    </table>
    <br/><br/>

    
    <br/>
    <input type="submit" value="Submit Command" />
  </form> 




</div>