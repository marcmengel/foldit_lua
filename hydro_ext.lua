

function hydrophillic_ext(start, mid, last)
    print(string.format("hydrophillic_ext(%s, %s)", start, last, mid))

    --[[try to make "external" items hydrophobic
        so if it's further from the center than minradius
        and the sidechain is more than epsilon further
        from the middle than the center is, make it hydrophobic --]]

    minradius = 2
    epsilon = 0.9

    llist = {'n','d'}
    hlist = {'e','k'}
    elist = {'t','r'}
    ccount = 0 --[[ counter to toggle red/blue --]]

    for i = start, last do
        if i ~= mid then
            ckband1 = band.AddBetweenSegments(i, mid, 4, 0)
            if ckband1 ~= 0 then
                ckband2 = band.AddBetweenSegments(i, mid, 0, 0)
                if ckband2 ~= 0 then
                    len1 = band.GetLength(ckband1) 
                    len2 = band.GetLength(ckband2) 
                    band.Delete(ckband2)
                else
                    len2 = 0
                end
                band.Delete(ckband1)
            else
                len2 = 0
            end
            ss = structure.GetSecondaryStructure(i)
            print("item: "..i.." len1: "..len1.." len2: "..len2.." ss: "..ss)
            if len2 > minradius then
                if len2 - len1 > epsilon then
                    selection.DeselectAll()
                    selection.SelectRange(i, i)
                    aa = 'r'
                    if ss == 'L' then
                        aa = llist[ccount % 2 + 1]
                    end
                    if ss == 'H' then
                        aa = hlist[ccount % 2 + 1]
                    end
                    if ss == 'E' then
                        aa = elist[ccount % 2 + 1]
                    end
                    print("changing to: "..aa)
                    structure.SetAminoAcidSelected(aa)
                    ccount = ccount + 1
                end
            end
        end
    end
end

 
function do_dialog() 
    local ask = dialog.CreateDialog("Test Dialog")
    ask.Instructions = dialog.AddLabel("Enter string: \n@dd set location \nsnxm add nxm sheet, \nhnn add n length helix")
    ask.Start = dialog.AddTextbox("start","71")
    ask.Mid = dialog.AddTextbox("mid","71")
    ask.Last = dialog.AddTextbox("last","135")
    ask.OK = dialog.AddButton("OK", 1)
    ask.Cancel = dialog.AddButton("Cancel", 0)
    if (dialog.Show(ask) > 0) then
        print(string.format("got protein string: %s %s %s", ask.Start.value, ask.Mid.value, ask.Last.value))
        behavior.SetWigglePower('m')
        hydrophillic_ext( tonumber(ask.Start.value), tonumber(ask.Mid.value), tonumber(ask.Last.value))
    end
end

do_dialog()



