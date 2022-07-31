

function addsheet(start,nsegspersheet,nsheets)
   print(string.format("addsheet(%s, %s, %s)", start, nsegspersheet, nsheets))

   --[[ loop parts --]]
   looplen = 2
   for subsheet = 1,nsheets - 1 do
       addloopsheet(start-looplen+subsheet*(looplen+nsegspersheet), nsegspersheet, looplen)
   end

   --[[ select sheet parts --]]
   selection.DeselectAll()
   for subsheet = 0,nsheets-1 do
       selection.SelectRange(start+subsheet*(looplen+nsegspersheet), start+subsheet*(looplen+nsegspersheet)+nsegspersheet-1) 
       print("selecting: "..(start+subsheet*(looplen+nsegspersheet))..".."..(start+subsheet*(looplen+nsegspersheet)+nsegspersheet-1))
   end
   structure.SetSecondaryStructureSelected('E')
   structure.SetAminoAcidSelected('v')  

   cleanlist = {}
   b1 = band.Add(start+1, start, start+2, 2, 1.55, 0 )
   cleanlist[#cleanlist+1] = b1
   for subsheet = 1,nsheets - 1 do
       bandloopsheet1(start-looplen+subsheet*(looplen+nsegspersheet), nsegspersheet, looplen, subsheet % 2, cleanlist)
   end
   behavior.SetWigglePower('l')
   behavior.SetClashImportance(0.0)
   structure.WiggleAll(2)
   unbandloopsheet1(cleanlist)
   structure.WiggleAll(1)
   behavior.SetClashImportance(1.0)

   for subsheet = 1,nsheets - 1 do
       bandloopsheet2(start-looplen+subsheet*(looplen+nsegspersheet), nsegspersheet, looplen)
   end

   structure.IdealSSSelected()

   freeze.FreezeSelected(true,true)

   -- try to fold this sheet
   -- structure.WiggleAll(10)
   structure.WiggleAll(2)

   return start+nsheets*(looplen+nsegspersheet)-looplen

end


function addloopsheet(start,n, looplen)
   print(string.format("addloopsheet(%s)", start))

   selection.DeselectAll()
   selection.SelectRange(start, start+looplen-1)
   structure.SetSecondaryStructureSelected('L')
   structure.SetAminoAcidSelected('g')  
   selection.DeselectAll()
   selection.SelectRange(start+1, start+1)
   if looplen > 3
   then
       selection.SelectRange(start+3, start+3)
   end
   structure.SetAminoAcidSelected('a')  

   return start+looplen
end

function unbandloopsheet1(cleanlist)
   -- remove bands to space so bands to tops can pull more
   for i = #cleanlist,1,-1 do
       if cleanlist[i] > 0 then
           print("deleting band " .. i)
           band.Delete(cleanlist[i])
       end
   end
end

function bandloopsheet1(start,n, looplen, direxp, cleanlist)
   --[[ 
   --   add bands to try to force it into shape 
   --   note doing both center and max atoms to try to pull it flat
   --   start with a band out to space to left or right to pull it
   --   in the right direction initially
   --]]
   
   if direxp == 0
   then 
       b1 = band.Add(start+1, start, start+2, n*5,0.12,0 )
   else
       b1 = band.Add(start+1, start, start+2, n*5, 2.98, 1.552 )
   end
   band.SetStrength(b1, 1.5)
   cleanlist[#cleanlist+1] = b1

   atomi = structure.GetAtomCount(start-1)-1 
   -- add bands to twist it flat?
   for i = 0,n-1,2 do
       b1=band.AddBetweenSegments(start-1-i, start + looplen+i, atomi, atomi)
       if b1 ~= 0 then
           band.SetGoalLength(b1, 3.5)
           band.SetStrength(b1, 1.5)
       end
   end
end

function bandloopsheet2(start,n, looplen)
   for i = 0,n-1 do
       b1=band.AddBetweenSegments(start-1-i, start + looplen+i )
       if b1 ~= 0 then
           band.SetGoalLength(b1, 3.5)
           band.SetStrength(b1, 1.5)
       end
   end

   return start+looplen
end

function addloop(start)
   print(string.format("addloop(%s)", start))

   selection.DeselectAll()
   selection.SelectRange(start, start+2)
   structure.SetSecondaryStructureSelected('L')
   structure.SetAminoAcidSelected('g')  
   selection.DeselectAll()
   selection.SelectRange(start+1, start+1)
   structure.SetAminoAcidSelected('a')  
  
   --[[ add bands to try to force it into shape 
   --  These are measured off the blueprint 
   --  distances, but made slightly smaller to pull
   --  better.(?) --]]
   b1=band.AddBetweenSegments(start-1, start+1)
   band.SetGoalLength(b1, 6.9)
   band.SetStrength(b1, 1.5)
   b1=band.AddBetweenSegments(start+3, start+1)
   band.SetGoalLength(b1, 5.9)
   band.SetStrength(b1, 1.5)
   b1=band.AddBetweenSegments(start-1, start+3)
   band.SetGoalLength(b1, 11.0)
   band.SetStrength(b1, 1.5)

   return start+3
end

function addhelix(start,n)
   print(string.format("addhelix(%s, %s)", start, n))

   selection.DeselectAll()
   selection.SelectRange(start, start+n-1)
   structure.SetSecondaryStructureSelected('H')
   structure.SetAminoAcidSelected('l')  
   structure.IdealSSSelected()
   freeze.FreezeSelected(true,true)

   return start+n
end

function protein_parser(cmdstr)
   print("protein_parser: "..cmdstr)
   firststart = -1
   oldstart = -1
   oldoldstart = -1
   while (cmdstr:len()>0) 
   do
       print("protein_parser: "..cmdstr)
       if (cmdstr:find('@')==1) then
          print("saw at sign...")
          k = 2
          if cmdstr:sub(3,3) >= '0' and cmdstr:sub(3,3) <= '9' then
             k = 3
          end
          if cmdstr:sub(4,4) >= '0' and cmdstr:sub(4,4) <= '9' then
             k = 4
          end
          start = tonumber(cmdstr:sub(2,k))
          print(string.format("start %s->%d", cmdstr:sub(2,k), start))
          if firststart == -1 then
             firststart = start
          end
          cmdstr = cmdstr:sub(k+1)
       elseif (cmdstr:find('s')==1) then
          oldoldstart = oldstart
          oldstart = start
          if cmdstr:sub(5,5) >= '0' and cmdstr:sub(5,5) <= '9' then
             endind = 5
             print("two digit sheet length:"..cmdstr:sub(4,5))
          else
             endind = 4
             print("one digit sheet length:"..cmdstr:sub(4,4))
          end
          start = addsheet(start, tonumber(cmdstr:sub(4,endind)),tonumber(cmdstr:sub(2,2)) )
          
          if oldoldstart ~= -1 then
              d1 = (oldstart - oldoldstart)/2
              d2 = (start - oldstart)/2
              b2 = band.AddBetweenSegments(oldoldstart + d1, start-1 - d2)
              if b2 ~= 0 then
                band.SetStrength(b2, 0.5)
              end
          end

          cmdstr = cmdstr:sub(endind+1)

          if (cmdstr:len()>0) then
             start = addloop(start)
          end

       elseif (cmdstr:find('h')==1) then
          oldoldstart = oldstart
          oldstart = start
          start = addhelix(start, cmdstr:sub(2,3))
          if oldoldstart ~= -1 then
              b2 = band.AddBetweenSegments(oldoldstart, start)
              if b2 ~= 0 then
                  band.SetStrength(b2, 0.5)
              end
          end

          cmdstr = cmdstr:sub(4)
          if (cmdstr:len()>0) then
             start = addloop(start)
          end
       else
          cmdstr = ""
       end

    end
    
    --[[ select whole thing, use wiggle for our bands 
    --   and ideal structure tools to try to get it
    --   into proper shape (i.e. so sheets might fold...)  
    --   --]]
    selection.DeselectAll()
    selection.SelectRange(firststart, start)
    structure.IdealizeSelected()
    behavior.SetWigglePower('m')
    structure.WiggleAll(5)
    freeze.UnfreezeAll()
    structure.WiggleAll(5)
    band.DisableAll(true)
    structure.WiggleAll(5)
 
    
end

function do_dialog() 
    local ask = dialog.CreateDialog("Test Dialog")
    ask.Instructions = dialog.AddLabel("Enter string: \n@dd set location \nsnxm add nxm sheet, \nhnn add n length helix")
    ask.Protein = dialog.AddTextbox("Protein", "@01s3x4h09h09s3x4")
    ask.OK = dialog.AddButton("OK", 1)
    ask.Cancel = dialog.AddButton("Cancel", 0)
    if (dialog.Show(ask) > 0) then
        print(string.format("got protein string: %s", ask.Protein.value))
        protein_parser(ask.Protein.value) 
    end
end

do_dialog()





