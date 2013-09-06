





get '/inquiry'
  erb :inquiry
end


get '/lookup:ssn'
  person = TestXXXPerson.ssn_is(params[:ssn]).first 
  erb :display
end

__END__





template :inquiry  do 

  <form>


  </form>


end






