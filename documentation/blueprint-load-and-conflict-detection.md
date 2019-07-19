# Load blueprint and detect conflicts

- load old remote blueprint from local storage
- load local blueprint from local storage
- Do we have an access token?
    
    yes:
    - load new remote blueprint from server
    - did it load successfully?
        
        yes:
        - is it different to the old remote blueprint?
            
            yes:
            - is the local blueprint different from the old remote?
                
                yes:
                - is the local blueprint different from the new remote?
                    
                    yes:
                    - prompt the user whether they want to keep the local or the remote
                    - end
                    
                    no: 
                    - overwrite the old remote with the new
                    - end
                
                no: 
                - overwrite the old and local blueprint with the new
                - end
            
            no:
            - is the local blueprint different from the old remote?
                
                yes: 
                - save the local blueprint to the server
                - did it work?
                    
                    yes: 
                    - overwrite the old remote with the local
                    - end
                    
                    no: 
                    - end
                
                no: 
                - end
        
        no: 
        - end
    
    no:
    - end
